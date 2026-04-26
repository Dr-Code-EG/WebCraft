import 'package:flutter/foundation.dart';

import '../catalog/block_registry.dart';
import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_types.dart';
import '../model/block_workspace.dart';

/// Where a node is currently attached inside its workspace. Returned by
/// [BlockWorkspaceController.locate] so attachment / detachment can be done
/// without re-walking the tree.
enum _ParentKind { root, next, slot, mouth }

class _Location {
  _Location.root(this.node, this.rootIndex)
      : kind = _ParentKind.root,
        parent = null,
        key = null,
        mouthIndex = null;
  _Location.next(this.parent, this.node)
      : kind = _ParentKind.next,
        rootIndex = null,
        key = null,
        mouthIndex = null;
  _Location.slot(this.parent, this.key, this.node)
      : kind = _ParentKind.slot,
        rootIndex = null,
        mouthIndex = null;
  _Location.mouth(this.parent, this.key, this.mouthIndex, this.node)
      : kind = _ParentKind.mouth,
        rootIndex = null;

  final _ParentKind kind;
  final BlockNode? parent;
  final BlockNode node;
  final int? rootIndex;
  final String? key;
  final int? mouthIndex;
}

/// Notifies UI of any structural / value / selection change in a single
/// [BlockWorkspace]. All edits go through this controller — block widgets
/// never mutate nodes directly.
class BlockWorkspaceController extends ChangeNotifier {
  BlockWorkspaceController(this.workspace);

  final BlockWorkspace workspace;

  String? _selectedId;
  String? get selectedId => _selectedId;

  void select(String? id) {
    if (_selectedId == id) return;
    _selectedId = id;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Lookup
  // -------------------------------------------------------------------------

  _Location? _locate(String id) {
    for (var i = 0; i < workspace.roots.length; i++) {
      final hit = _locateIn(workspace.roots[i], id);
      if (hit != null) return hit;
      if (workspace.roots[i].id == id) {
        return _Location.root(workspace.roots[i], i);
      }
    }
    return null;
  }

  _Location? _locateIn(BlockNode parent, String id) {
    // Slot children
    for (final entry in parent.slotChildren.entries) {
      final c = entry.value;
      if (c == null) continue;
      if (c.id == id) return _Location.slot(parent, entry.key, c);
      final inner = _locateIn(c, id);
      if (inner != null) return inner;
    }
    // Mouth stacks
    for (final entry in parent.mouthStacks.entries) {
      for (var i = 0; i < entry.value.length; i++) {
        final n = entry.value[i];
        if (n.id == id) return _Location.mouth(parent, entry.key, i, n);
        final inner = _locateIn(n, id);
        if (inner != null) return inner;
      }
    }
    // Next chain
    if (parent.next != null) {
      if (parent.next!.id == id) return _Location.next(parent, parent.next!);
      final inner = _locateIn(parent.next!, id);
      if (inner != null) return inner;
    }
    return null;
  }

  BlockNode? findById(String id) => _locate(id)?.node;

  // -------------------------------------------------------------------------
  // Attach / detach primitives
  // -------------------------------------------------------------------------

  /// Splice `node` out of its current parent and return it. The detached
  /// subtree keeps its own children and full `next` chain intact, so callers
  /// (move/insert ops) can reattach the entire stack at once.
  ///
  /// Note: when detaching from a next-link (e.g. removing B from A→B→C),
  /// the parent's chain is truncated (A.next = null). The returned node
  /// still owns B→C; callers wanting to splice B out while preserving A→C
  /// must save `loc.node.next` first and reattach it themselves.
  BlockNode? _detach(String id) {
    final loc = _locate(id);
    if (loc == null) return null;
    switch (loc.kind) {
      case _ParentKind.root:
        workspace.roots.removeAt(loc.rootIndex!);
        break;
      case _ParentKind.next:
        loc.parent!.next = null;
        break;
      case _ParentKind.slot:
        loc.parent!.slotChildren[loc.key!] = null;
        break;
      case _ParentKind.mouth:
        loc.parent!.mouthStacks[loc.key!]!.removeAt(loc.mouthIndex!);
        break;
    }
    return loc.node;
  }

  /// Returns `true` when `subtree` is the same node as `candidateAncestor`
  /// or contains it anywhere in its descendants. Used to reject illegal
  /// drops that would create a cycle.
  bool _contains(BlockNode subtree, String candidateId) {
    return subtree.walk().any((n) => n.id == candidateId);
  }

  // -------------------------------------------------------------------------
  // Public ops
  // -------------------------------------------------------------------------

  void addRootAt(BlockNode node, double x, double y) {
    node.x = x;
    node.y = y;
    workspace.roots.add(node);
    _selectedId = node.id;
    notifyListeners();
  }

  void moveRoot(String rootId, double x, double y) {
    for (final r in workspace.roots) {
      if (r.id == rootId) {
        r.x = x;
        r.y = y;
        notifyListeners();
        return;
      }
    }
  }

  /// Move a block (with its subtree) onto the canvas at (x, y) as a new
  /// root. Detaches from any current parent first.
  void moveToRoot(String id, double x, double y) {
    final loc = _locate(id);
    if (loc == null) return;
    if (loc.kind == _ParentKind.root) {
      moveRoot(id, x, y);
      return;
    }
    final node = _detach(id);
    if (node == null) return;
    node.x = x;
    node.y = y;
    workspace.roots.add(node);
    notifyListeners();
  }

  /// Insert `dragged` (with its full chain) immediately AFTER `targetId`
  /// in the next-chain. Returns false on type-mismatch / cycle.
  bool insertAsNext(String targetId, BlockNode dragged) {
    final loc = _locate(targetId);
    if (loc == null) return false;
    if (_contains(dragged, targetId)) return false;
    final targetSpec = BlockRegistry.instance.lookup(loc.node.specId);
    final draggedSpec = BlockRegistry.instance.lookup(dragged.specId);
    if (targetSpec == null || draggedSpec == null) return false;
    if (!targetSpec.shape.hasNextNotch) return false;
    if (!draggedSpec.shape.hasPrevNotch) return false;

    // If dragged is currently in the workspace, detach it.
    if (_locate(dragged.id) != null) {
      _detach(dragged.id);
    }
    // Splice in: dragged.tail.next = oldNext; target.next = dragged
    final oldNext = loc.node.next;
    var tail = dragged;
    while (tail.next != null) {
      tail = tail.next!;
    }
    tail.next = oldNext;
    loc.node.next = dragged;
    _selectedId = dragged.id;
    notifyListeners();
    return true;
  }

  /// Drop `dragged` into a typed expression slot. Returns false on type
  /// mismatch, cycle, or shape mismatch (slots only accept expressions).
  bool insertIntoSlot(String parentId, String slotName, BlockNode dragged) {
    final loc = _locate(parentId);
    if (loc == null) return false;
    if (_contains(dragged, parentId)) return false;

    final parentSpec = BlockRegistry.instance.lookup(loc.node.specId);
    final draggedSpec = BlockRegistry.instance.lookup(dragged.specId);
    if (parentSpec == null || draggedSpec == null) return false;
    if (draggedSpec.shape != BlockShape.expression) return false;
    final slotSpec = parentSpec.slot(slotName);
    if (slotSpec == null) return false;
    if (!slotSpec.accepts.accepts(draggedSpec.returnType)) return false;

    if (_locate(dragged.id) != null) _detach(dragged.id);
    // If the slot already has a child, detach it back to the canvas as a
    // root at the parent's position so it isn't lost.
    final existing = loc.node.slotChildren[slotName];
    if (existing != null) {
      loc.node.slotChildren[slotName] = null;
      existing.x = loc.node.x + 24;
      existing.y = loc.node.y + 60;
      workspace.roots.add(existing);
    }
    loc.node.slotChildren[slotName] = dragged;
    _selectedId = dragged.id;
    notifyListeners();
    return true;
  }

  /// Append `dragged` (with chain) to a C-block mouth.
  bool appendToMouth(String parentId, String mouthName, BlockNode dragged) {
    final loc = _locate(parentId);
    if (loc == null) return false;
    if (_contains(dragged, parentId)) return false;

    final parentSpec = BlockRegistry.instance.lookup(loc.node.specId);
    final draggedSpec = BlockRegistry.instance.lookup(dragged.specId);
    if (parentSpec == null || draggedSpec == null) return false;
    if (parentSpec.mouth(mouthName) == null) return false;
    if (!draggedSpec.shape.hasPrevNotch) return false;

    if (_locate(dragged.id) != null) _detach(dragged.id);
    loc.node.mouthStacks
        .putIfAbsent(mouthName, () => <BlockNode>[])
        .add(dragged);
    _selectedId = dragged.id;
    notifyListeners();
    return true;
  }

  /// Delete a subtree (the node + everything attached to it) entirely.
  void delete(String id) {
    if (_locate(id) == null) return;
    _detach(id);
    if (_selectedId == id) _selectedId = null;
    notifyListeners();
  }

  /// Update an inline field value.
  void setField(String id, String fieldName, String value) {
    final loc = _locate(id);
    if (loc == null) return;
    loc.node.fieldValues[fieldName] = value;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // Variable manager
  // -------------------------------------------------------------------------

  bool addVariable(String name,
      {BlockType type = BlockType.any, String defaultValue = ''}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    if (workspace.variables.any((v) => v.name == trimmed)) return false;
    workspace.variables.add(VariableDecl(
      name: trimmed,
      type: type,
      defaultValue: defaultValue,
    ));
    notifyListeners();
    return true;
  }

  void removeVariable(String name) {
    workspace.variables.removeWhere((v) => v.name == name);
    notifyListeners();
  }

  bool renameVariable(String oldName, String newName) {
    final trimmed = newName.trim();
    if (trimmed.isEmpty || trimmed == oldName) return false;
    if (workspace.variables.any((v) => v.name == trimmed)) return false;
    final v = workspace.variables.where((v) => v.name == oldName).firstOrNull;
    if (v == null) return false;
    v.name = trimmed;
    // Update only variable-kind field values that reference this variable —
    // text/element/dropdown fields that happen to hold the same string must
    // not be silently rewritten.
    for (final root in workspace.roots) {
      for (final n in root.walk()) {
        final spec = BlockRegistry.instance.lookup(n.specId);
        if (spec == null) continue;
        for (final entry in List.of(n.fieldValues.entries)) {
          if (entry.value != oldName) continue;
          final fieldSpec = spec.field(entry.key);
          if (fieldSpec?.kind != BlockFieldKind.variable) continue;
          n.fieldValues[entry.key] = trimmed;
        }
      }
    }
    notifyListeners();
    return true;
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (it.moveNext()) return it.current;
    return null;
  }
}
