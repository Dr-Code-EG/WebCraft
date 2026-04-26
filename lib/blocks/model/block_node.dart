import 'dart:math';

import 'block_spec.dart';

/// Concrete instance of a [BlockSpec] zoomed into a workspace. Carries the
/// values for its inline fields, the children attached to its slots / mouths
/// and (if it's a stackable block) a pointer to the next block in the stack.
class BlockNode {
  BlockNode({
    String? id,
    required this.specId,
    Map<String, String>? fieldValues,
    Map<String, BlockNode?>? slotChildren,
    Map<String, List<BlockNode>>? mouthStacks,
    this.next,
    this.x = 0,
    this.y = 0,
  })  : id = id ?? _newId(),
        fieldValues = Map<String, String>.from(fieldValues ?? const {}),
        slotChildren = Map<String, BlockNode?>.from(slotChildren ?? const {}),
        mouthStacks = Map<String, List<BlockNode>>.from(
            mouthStacks ?? const <String, List<BlockNode>>{});

  final String id;
  final String specId;

  final Map<String, String> fieldValues;
  final Map<String, BlockNode?> slotChildren;
  final Map<String, List<BlockNode>> mouthStacks;

  /// Next block in the vertical stack (if this block has a bottom notch).
  BlockNode? next;

  /// Workspace-space position. Only meaningful for the root node of a stack;
  /// children inherit their parent's coordinates implicitly.
  double x;
  double y;

  // ---------- helpers ----------

  /// Iterate all descendants depth-first, including this node.
  Iterable<BlockNode> walk() sync* {
    yield this;
    for (final c in slotChildren.values) {
      if (c != null) yield* c.walk();
    }
    for (final stack in mouthStacks.values) {
      for (final n in stack) {
        yield* n.walk();
      }
    }
    if (next != null) yield* next!.walk();
  }

  /// Deep-copy the node and all its children, generating fresh ids.
  BlockNode duplicate() {
    return BlockNode(
      specId: specId,
      fieldValues: Map<String, String>.from(fieldValues),
      slotChildren: {
        for (final e in slotChildren.entries) e.key: e.value?.duplicate(),
      },
      mouthStacks: {
        for (final e in mouthStacks.entries)
          e.key: e.value.map((n) => n.duplicate()).toList(),
      },
      next: next?.duplicate(),
      x: x,
      y: y,
    );
  }

  // ---------- JSON ----------

  Map<String, dynamic> toJson() => {
        'id': id,
        'specId': specId,
        if (fieldValues.isNotEmpty) 'fields': fieldValues,
        if (slotChildren.isNotEmpty)
          'slots': {
            for (final e in slotChildren.entries)
              if (e.value != null) e.key: e.value!.toJson(),
          },
        if (mouthStacks.isNotEmpty)
          'mouths': {
            for (final e in mouthStacks.entries)
              e.key: e.value.map((n) => n.toJson()).toList(),
          },
        if (next != null) 'next': next!.toJson(),
        if (x != 0) 'x': x,
        if (y != 0) 'y': y,
      };

  factory BlockNode.fromJson(Map<String, dynamic> j) {
    return BlockNode(
      id: j['id'] as String?,
      specId: j['specId'] as String,
      fieldValues: (j['fields'] as Map?)?.cast<String, String>(),
      slotChildren: (j['slots'] as Map?)?.map(
        (k, v) => MapEntry(k as String,
            v == null ? null : BlockNode.fromJson(v as Map<String, dynamic>)),
      ),
      mouthStacks: (j['mouths'] as Map?)?.map(
        (k, v) => MapEntry(
          k as String,
          (v as List)
              .map((e) => BlockNode.fromJson(e as Map<String, dynamic>))
              .toList(),
        ),
      ),
      next: j['next'] == null
          ? null
          : BlockNode.fromJson(j['next'] as Map<String, dynamic>),
      x: (j['x'] as num?)?.toDouble() ?? 0,
      y: (j['y'] as num?)?.toDouble() ?? 0,
    );
  }
}

String _newId() {
  final r = Random();
  final n = r.nextInt(1 << 32);
  final t = DateTime.now().microsecondsSinceEpoch & 0xFFFFFFFF;
  return 'b_${t.toRadixString(16)}_${n.toRadixString(16)}';
}
