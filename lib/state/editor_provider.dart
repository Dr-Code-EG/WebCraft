import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../models/component_spec.dart';
import '../models/element_node.dart';
import '../models/page_node.dart';
import '../models/project.dart';

/// Drives the visual editor: selection, mutations, undo/redo (snapshot-based).
class EditorProvider extends ChangeNotifier {
  EditorProvider(this.project);

  final Project project;
  String? _selectedElementId;
  bool _dirty = false;

  // Undo/redo: history of JSON snapshots. We snapshot *before* each mutation
  // and push onto _undo; redo is filled by `undo()` and cleared by mutations.
  final List<String> _undo = <String>[];
  final List<String> _redo = <String>[];
  static const int _historyLimit = 60;

  String? get selectedElementId => _selectedElementId;
  bool get dirty => _dirty;
  bool get canUndo => _undo.isNotEmpty;
  bool get canRedo => _redo.isNotEmpty;

  String _snapshot() => jsonEncode(project.toJson());

  void _pushHistory() {
    final snap = _snapshot();
    if (_undo.isNotEmpty && _undo.last == snap) return;
    _undo.add(snap);
    if (_undo.length > _historyLimit) {
      _undo.removeAt(0);
    }
    _redo.clear();
  }

  /// Roll back the most recent change. No-op when [canUndo] is false.
  void undo() {
    if (_undo.isEmpty) return;
    final current = _snapshot();
    final prev = _undo.removeLast();
    _redo.add(current);
    project.restoreFromJson(jsonDecode(prev) as Map<String, dynamic>);
    _selectedElementId = null;
    _dirty = true;
    notifyListeners();
  }

  /// Re-apply the most recently undone change. No-op when [canRedo] is false.
  void redo() {
    if (_redo.isEmpty) return;
    final current = _snapshot();
    final next = _redo.removeLast();
    _undo.add(current);
    project.restoreFromJson(jsonDecode(next) as Map<String, dynamic>);
    _selectedElementId = null;
    _dirty = true;
    notifyListeners();
  }

  PageNode get activePage => project.activePage;

  ElementNode? get selectedElement {
    if (_selectedElementId == null) return null;
    return _findById(activePage.root, _selectedElementId!);
  }

  void select(String? id) {
    _selectedElementId = id;
    notifyListeners();
  }

  void selectPage(String pageId) {
    _pushHistory();
    project.activePageId = pageId;
    _selectedElementId = null;
    _markDirty();
  }

  void addPage(String name) {
    _pushHistory();
    final fileName = '${_slug(name)}.html';
    final page = PageNode(
      name: name,
      fileName: fileName,
      root: ElementNode.defaults(ElementType.container),
    );
    project.pages.add(page);
    project.activePageId = page.id;
    _markDirty();
  }

  void deletePage(String pageId) {
    if (project.pages.length <= 1) return;
    _pushHistory();
    project.pages.removeWhere((p) => p.id == pageId);
    project.activePageId = project.pages.first.id;
    _markDirty();
  }

  /// Add a new element to the currently selected container, or to root.
  void addElement(ElementType type) {
    _pushHistory();
    final node = ElementNode.defaults(type);
    final parent = _resolveDropParent();
    parent.children.add(node);
    _selectedElementId = node.id;
    _markDirty();
  }

  /// Add [type] as a child of element [parentId] (must accept children).
  void addElementInside(ElementType type, String parentId) {
    final parent = _findById(activePage.root, parentId);
    if (parent == null || !parent.type.acceptsChildren) return;
    _pushHistory();
    final node = ElementNode.defaults(type);
    parent.children.add(node);
    _selectedElementId = node.id;
    _markDirty();
  }

  void deleteElement(String id) {
    if (id == activePage.root.id) return;
    _pushHistory();
    _removeById(activePage.root, id);
    if (_selectedElementId == id) _selectedElementId = null;
    _markDirty();
  }

  void duplicateElement(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null) return;
    _pushHistory();
    final clone = found.parent.children[found.index].copyWithNewIds();
    found.parent.children.insert(found.index + 1, clone);
    _selectedElementId = clone.id;
    _markDirty();
  }

  void moveElementUp(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null || found.index == 0) return;
    _pushHistory();
    final list = found.parent.children;
    final node = list.removeAt(found.index);
    list.insert(found.index - 1, node);
    _markDirty();
  }

  void moveElementDown(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null) return;
    final list = found.parent.children;
    if (found.index >= list.length - 1) return;
    _pushHistory();
    final node = list.removeAt(found.index);
    list.insert(found.index + 1, node);
    _markDirty();
  }

  /// Move [id] to be a sibling of [referenceId] at the given direction
  /// (`above` / `below`) — used by drag-to-reorder in the tree.
  void reorderElement(String id, String referenceId, {required bool above}) {
    if (id == referenceId) return;
    final src = _findParentAndIndex(activePage.root, id);
    final dstProbe = _findParentAndIndex(activePage.root, referenceId);
    if (src == null || dstProbe == null) return;
    // Disallow moving a node into one of its descendants.
    if (_findById(src.parent.children[src.index], referenceId) != null) {
      return;
    }
    _pushHistory();
    final node = src.parent.children.removeAt(src.index);
    // Re-resolve destination index after removal (in case in same parent).
    final newDst = _findParentAndIndex(activePage.root, referenceId);
    if (newDst == null) {
      // Reference was the just-removed item: bail out and put it back.
      src.parent.children.insert(src.index, node);
      return;
    }
    final insertAt = above ? newDst.index : newDst.index + 1;
    newDst.parent.children.insert(insertAt, node);
    _selectedElementId = node.id;
    _markDirty();
  }

  void updateProp(String elementId, String key, String value) {
    final el = _findById(activePage.root, elementId);
    if (el == null) return;
    _pushHistory();
    if (value.isEmpty) {
      el.props.remove(key);
    } else {
      el.props[key] = value;
    }
    _markDirty();
  }

  void updateStyle(String elementId, String key, String value) {
    final el = _findById(activePage.root, elementId);
    if (el == null) return;
    _pushHistory();
    if (value.isEmpty) {
      el.style.remove(key);
    } else {
      el.style[key] = value;
    }
    _markDirty();
  }

  /// Replace the entire project state (pages, workspaces) from the given
  /// JSON map — used by ZIP/JSON import. Captures history so the user can
  /// undo the import.
  void replaceFromJson(Map<String, dynamic> json) {
    _pushHistory();
    project.restoreFromJson(json);
    _selectedElementId = null;
    _markDirty();
  }

  void markSaved() {
    _dirty = false;
    notifyListeners();
  }

  /// Replace the entire theme variable map.
  void setThemeVars(Map<String, String> vars) {
    _pushHistory();
    project.themeVars
      ..clear()
      ..addAll(vars);
    _markDirty();
  }

  /// Update / insert a single CSS custom property.
  void setThemeVar(String key, String value) {
    if (key.isEmpty) return;
    _pushHistory();
    project.themeVars[key] = value;
    _markDirty();
  }

  void removeThemeVar(String key) {
    if (!project.themeVars.containsKey(key)) return;
    _pushHistory();
    project.themeVars.remove(key);
    _markDirty();
  }

  void setCustomCss(String css) {
    if (project.customCss == css) return;
    _pushHistory();
    project.customCss = css;
    _markDirty();
  }

  /// Save the currently selected element subtree as a reusable component.
  /// Returns the saved component, or `null` if nothing is selected.
  ComponentSpec? saveSelectionAsComponent(String name) {
    final id = _selectedElementId;
    if (id == null || id == activePage.root.id) return null;
    final el = _findById(activePage.root, id);
    if (el == null) return null;
    _pushHistory();
    final clone = el.copyWithNewIds();
    final comp =
        ComponentSpec(name: name.isEmpty ? clone.type.name : name, root: clone);
    project.components.add(comp);
    _markDirty();
    return comp;
  }

  /// Insert a saved component into the current drop parent (selected
  /// container, or the root if no container is selected). Returns the new
  /// node's id so callers can select it.
  String insertComponent(ComponentSpec comp) {
    _pushHistory();
    final clone = comp.root.copyWithNewIds();
    final parent = _resolveDropParent();
    parent.children.add(clone);
    _selectedElementId = clone.id;
    _markDirty();
    return clone.id;
  }

  void deleteComponent(String componentId) {
    final idx = project.components.indexWhere((c) => c.id == componentId);
    if (idx < 0) return;
    _pushHistory();
    project.components.removeAt(idx);
    _markDirty();
  }

  /// Notify listeners that block workspaces (event handlers, variables) on
  /// the project changed externally — e.g. after returning from the Block
  /// Workshop screen. Forces a re-paint of Logic-tab chips and persistence.
  void markBlocksChanged() {
    _markDirty();
  }

  void _markDirty() {
    _dirty = true;
    notifyListeners();
  }

  ElementNode _resolveDropParent() {
    if (_selectedElementId != null) {
      final el = _findById(activePage.root, _selectedElementId!);
      if (el != null && el.type.acceptsChildren) return el;
    }
    return activePage.root;
  }

  ElementNode? _findById(ElementNode root, String id) {
    if (root.id == id) return root;
    for (final c in root.children) {
      final r = _findById(c, id);
      if (r != null) return r;
    }
    return null;
  }

  bool _removeById(ElementNode root, String id) {
    for (var i = 0; i < root.children.length; i++) {
      if (root.children[i].id == id) {
        root.children.removeAt(i);
        return true;
      }
      if (_removeById(root.children[i], id)) return true;
    }
    return false;
  }

  _ParentIndex? _findParentAndIndex(ElementNode root, String id) {
    for (var i = 0; i < root.children.length; i++) {
      if (root.children[i].id == id) {
        return _ParentIndex(root, i);
      }
      final inner = _findParentAndIndex(root.children[i], id);
      if (inner != null) return inner;
    }
    return null;
  }

  static String _slug(String name) {
    final lower = name.trim().toLowerCase();
    final s = lower.replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
    final trimmed = s.replaceAll(RegExp(r'(^-+|-+$)'), '');
    return trimmed.isEmpty ? 'page' : trimmed;
  }
}

class _ParentIndex {
  _ParentIndex(this.parent, this.index);
  final ElementNode parent;
  final int index;
}
