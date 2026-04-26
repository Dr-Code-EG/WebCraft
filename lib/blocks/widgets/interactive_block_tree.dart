import 'package:flutter/material.dart';

import '../catalog/block_registry.dart';
import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_types.dart';
import '../state/block_workspace_controller.dart';
import 'block_drag_payload.dart';
import 'block_widget.dart';

/// Interactive renderer of a single root [BlockNode] (and its full chain /
/// subtree). Handles long-press drag, drop targets for slots / mouths /
/// next-notch, tap selection, and dispatches field edits to a host callback.
///
/// Mirrors the structure of [BlockWidget] (same painter, same notch metrics)
/// but mutates state through a [BlockWorkspaceController].
class InteractiveBlockTree extends StatelessWidget {
  const InteractiveBlockTree({
    super.key,
    required this.root,
    required this.controller,
    required this.onEditField,
  });

  final BlockNode root;
  final BlockWorkspaceController controller;

  /// Called when a field chip is tapped. Host opens an edit dialog and
  /// returns the new value (or null to cancel).
  final Future<String?> Function(BlockNode node, BlockFieldSpec field) onEditField;

  @override
  Widget build(BuildContext context) {
    return _InteractiveBlock(
      node: root,
      controller: controller,
      onEditField: onEditField,
    );
  }
}

class _InteractiveBlock extends StatelessWidget {
  const _InteractiveBlock({
    required this.node,
    required this.controller,
    required this.onEditField,
  });

  final BlockNode node;
  final BlockWorkspaceController controller;
  final Future<String?> Function(BlockNode node, BlockFieldSpec field) onEditField;

  @override
  Widget build(BuildContext context) {
    final spec = BlockRegistry.instance.lookup(node.specId);
    if (spec == null) {
      return BlockWidget(node: node);
    }
    final selected = controller.selectedId == node.id;

    final blockBody = _renderSelf(context, spec, selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Long-press grabs THIS block + its full chain. Hit-test is exactly
        // the area of the block (not its `next`, which renders below in the
        // same Column). The recursive child has its own Draggable, so a
        // long-press on a deeper block grabs that smaller subtree.
        LongPressDraggable<BlockDragPayload>(
          data: BlockDragPayload.fromWorkspace(node),
          delay: const Duration(milliseconds: 220),
          dragAnchorStrategy: pointerDragAnchorStrategy,
          feedback: Material(
            type: MaterialType.transparency,
            child: Opacity(
              opacity: 0.92,
              child: BlockWidget(node: node),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.25, child: blockBody),
          child: blockBody,
        ),
        if (node.next != null)
          Transform.translate(
            offset: const Offset(0, -kNotchHeight),
            child: _InteractiveBlock(
              node: node.next!,
              controller: controller,
              onEditField: onEditField,
            ),
          ),
        // Drop zone at the very bottom of the chain — accept blocks here
        // and snap them to the tail.
        if (node.next == null && spec.shape.hasNextNotch)
          _NextDropZone(
            targetId: node.id,
            controller: controller,
          ),
      ],
    );
  }

  Widget _renderSelf(BuildContext context, BlockSpec spec, bool selected) {
    final color = colorFor(spec);
    final pieces = _splitTemplate(spec.template);

    final inner = Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 14, 8),
      child: DefaultTextStyle.merge(
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            for (final p in pieces)
              _buildPiece(context, spec, p),
          ],
        ),
      ),
    );

    Widget body = GestureDetector(
      onTap: () => controller.select(node.id),
      child: CustomPaint(
        painter: _BlockShapePainterCompat(color: color, shape: spec.shape),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: kBlockMinHeight),
          child: Stack(
            children: [
              inner,
              if (selected)
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(kCornerRadius),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (spec.shape == BlockShape.cBlock && spec.mouths.isNotEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          for (final m in spec.mouths)
            _MouthDropZone(
              parentId: node.id,
              mouthName: m.name,
              color: color,
              controller: controller,
              children: node.mouthStacks[m.name] ?? const [],
              onEditField: onEditField,
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: kNotchHeight),
      child: body,
    );
  }

  Widget _buildPiece(BuildContext context, BlockSpec spec, _Piece p) {
    if (p.kind == _PieceKind.text) return Text(p.value);
    for (final f in spec.fields) {
      if (f.name == p.value) {
        final value = node.fieldValues[p.value] ?? f.defaultValue;
        return _InteractiveFieldChip(
          field: f,
          value: value,
          onTap: () async {
            final next = await onEditField(node, f);
            if (next != null) controller.setField(node.id, f.name, next);
          },
        );
      }
    }
    for (final s in spec.slots) {
      if (s.name == p.value) {
        final child = node.slotChildren[p.value];
        return _SlotDropZone(
          parentId: node.id,
          slotName: s.name,
          accepts: s.accepts,
          controller: controller,
          child: child,
          onEditField: onEditField,
        );
      }
    }
    return Text('%${p.value}');
  }
}

// ---------------------------------------------------------------------------
// Drop zones
// ---------------------------------------------------------------------------

class _NextDropZone extends StatelessWidget {
  const _NextDropZone({required this.targetId, required this.controller});

  final String targetId;
  final BlockWorkspaceController controller;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Transform.translate(
      offset: const Offset(0, -kNotchHeight),
      child: DragTarget<BlockDragPayload>(
        onWillAcceptWithDetails: (d) {
          final spec = d.data.isFromToolbox
              ? d.data.spec!
              : BlockRegistry.instance.lookup(d.data.node!.specId);
          if (spec == null) return false;
          return spec.shape.hasPrevNotch;
        },
        onAcceptWithDetails: (d) {
          BlockNode child;
          if (d.data.isFromToolbox) {
            child = BlockNode(specId: d.data.spec!.id);
          } else {
            child = d.data.node!;
          }
          controller.insertAsNext(targetId, child);
        },
        builder: (context, candidate, rejected) {
          final hovering = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            margin: const EdgeInsetsDirectional.only(start: 8),
            height: hovering ? 16 : 8,
            width: hovering ? 80 : 40,
            decoration: BoxDecoration(
              color: hovering
                  ? cs.primary.withOpacity(0.6)
                  : cs.outlineVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        },
      ),
    );
  }
}

class _SlotDropZone extends StatelessWidget {
  const _SlotDropZone({
    required this.parentId,
    required this.slotName,
    required this.accepts,
    required this.controller,
    required this.child,
    required this.onEditField,
  });

  final String parentId;
  final String slotName;
  final BlockType accepts;
  final BlockWorkspaceController controller;
  final BlockNode? child;
  final Future<String?> Function(BlockNode node, BlockFieldSpec field) onEditField;

  @override
  Widget build(BuildContext context) {
    return DragTarget<BlockDragPayload>(
      onWillAcceptWithDetails: (d) {
        final spec = d.data.isFromToolbox
            ? d.data.spec!
            : BlockRegistry.instance.lookup(d.data.node!.specId);
        if (spec == null) return false;
        if (spec.shape != BlockShape.expression) return false;
        return accepts.accepts(spec.returnType);
      },
      onAcceptWithDetails: (d) {
        BlockNode dropped;
        if (d.data.isFromToolbox) {
          dropped = BlockNode(specId: d.data.spec!.id);
        } else {
          dropped = d.data.node!;
        }
        controller.insertIntoSlot(parentId, slotName, dropped);
      },
      builder: (context, candidate, rejected) {
        final hovering = candidate.isNotEmpty;
        if (child != null) {
          return _InteractiveBlock(
            node: child!,
            controller: controller,
            onEditField: onEditField,
          );
        }
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: hovering
                ? Colors.white.withOpacity(0.85)
                : Colors.black.withOpacity(0.18),
            borderRadius: BorderRadius.circular(10),
            border: hovering
                ? Border.all(color: Colors.white, width: 1.4)
                : null,
          ),
          child: Text(
            accepts == BlockType.any ? '⋯' : accepts.id,
            style: TextStyle(
              color: hovering ? Colors.black : Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        );
      },
    );
  }
}

class _MouthDropZone extends StatelessWidget {
  const _MouthDropZone({
    required this.parentId,
    required this.mouthName,
    required this.color,
    required this.controller,
    required this.children,
    required this.onEditField,
  });

  final String parentId;
  final String mouthName;
  final Color color;
  final BlockWorkspaceController controller;
  final List<BlockNode> children;
  final Future<String?> Function(BlockNode node, BlockFieldSpec field) onEditField;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(left: 12),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: color, width: 12),
          bottom: BorderSide(color: color, width: 6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, left: 2),
            child: Text(
              mouthName,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          for (final c in children)
            _InteractiveBlock(
              node: c,
              controller: controller,
              onEditField: onEditField,
            ),
          DragTarget<BlockDragPayload>(
            onWillAcceptWithDetails: (d) {
              final spec = d.data.isFromToolbox
                  ? d.data.spec!
                  : BlockRegistry.instance.lookup(d.data.node!.specId);
              if (spec == null) return false;
              return spec.shape.hasPrevNotch;
            },
            onAcceptWithDetails: (d) {
              BlockNode dropped;
              if (d.data.isFromToolbox) {
                dropped = BlockNode(specId: d.data.spec!.id);
              } else {
                dropped = d.data.node!;
              }
              controller.appendToMouth(parentId, mouthName, dropped);
            },
            builder: (context, candidate, rejected) {
              final hovering = candidate.isNotEmpty;
              return Container(
                width: hovering ? 120 : 80,
                height: hovering ? 22 : 14,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: hovering
                      ? color.withOpacity(0.45)
                      : color.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(6),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InteractiveFieldChip extends StatelessWidget {
  const _InteractiveFieldChip({
    required this.field,
    required this.value,
    required this.onTap,
  });
  final BlockFieldSpec field;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? field.placeholder : value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            display.isEmpty ? '…' : display,
            style: const TextStyle(
              color: Color(0xFF111827),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Local copies of the painter / template parser. Keeping these here avoids
// exposing block_widget.dart's private types — the painter itself is a
// faithful re-implementation of the read-only one.
// ---------------------------------------------------------------------------

class _BlockShapePainterCompat extends CustomPainter {
  _BlockShapePainterCompat({required this.color, required this.shape});

  final Color color;
  final BlockShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    path.moveTo(kCornerRadius, 0);
    if (shape.hasPrevNotch) {
      path.lineTo(kNotchInset, 0);
      path.lineTo(kNotchInset + 4, kNotchHeight);
      path.lineTo(kNotchInset + kNotchWidth - 4, kNotchHeight);
      path.lineTo(kNotchInset + kNotchWidth, 0);
    }
    path.lineTo(w - kCornerRadius, 0);
    path.quadraticBezierTo(w, 0, w, kCornerRadius);
    path.lineTo(w, h - kCornerRadius - kNotchHeight);
    path.quadraticBezierTo(
        w, h - kNotchHeight, w - kCornerRadius, h - kNotchHeight);

    if (shape.hasNextNotch) {
      path.lineTo(kNotchInset + kNotchWidth, h - kNotchHeight);
      path.lineTo(kNotchInset + kNotchWidth - 4, h);
      path.lineTo(kNotchInset + 4, h);
      path.lineTo(kNotchInset, h - kNotchHeight);
    }
    path.lineTo(kCornerRadius, h - kNotchHeight);
    path.quadraticBezierTo(
        0, h - kNotchHeight, 0, h - kCornerRadius - kNotchHeight);
    path.lineTo(0, kCornerRadius);
    path.quadraticBezierTo(0, 0, kCornerRadius, 0);
    path.close();

    final fill = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = Color.lerp(color, Colors.black, 0.18)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _BlockShapePainterCompat old) =>
      old.color != color || old.shape != shape;
}

enum _PieceKind { text, ref }

class _Piece {
  _Piece(this.kind, this.value);
  final _PieceKind kind;
  final String value;
}

List<_Piece> _splitTemplate(String template) {
  final out = <_Piece>[];
  final regex = RegExp(r'%([A-Za-z_][A-Za-z0-9_]*)');
  var last = 0;
  for (final m in regex.allMatches(template)) {
    if (m.start > last) {
      out.add(_Piece(_PieceKind.text, template.substring(last, m.start)));
    }
    out.add(_Piece(_PieceKind.ref, m.group(1)!));
    last = m.end;
  }
  if (last < template.length) {
    out.add(_Piece(_PieceKind.text, template.substring(last)));
  }
  return out;
}
