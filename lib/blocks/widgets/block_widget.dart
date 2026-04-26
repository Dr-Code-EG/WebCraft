import 'package:flutter/material.dart';

import '../catalog/block_registry.dart';
import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_types.dart';

/// Visual renderer for a single block (and its attached `next` chain) using a
/// jigsaw-notched [CustomPaint] background. This is the read-only Phase B0
/// preview — interaction (drag, snap, edit) lands in Phase B1+.
class BlockWidget extends StatelessWidget {
  const BlockWidget({super.key, required this.node});

  final BlockNode node;

  @override
  Widget build(BuildContext context) {
    final spec = BlockRegistry.instance.lookup(node.specId);
    if (spec == null) {
      return _MissingSpec(specId: node.specId);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SingleBlock(node: node, spec: spec),
        if (node.next != null)
          // Stack continuation; rendered immediately below so the bottom
          // notch of one block lines up with the top notch of the next.
          Transform.translate(
            offset: const Offset(0, -kNotchHeight),
            child: BlockWidget(node: node.next!),
          ),
      ],
    );
  }
}

const double kNotchHeight = 6;
const double kNotchWidth = 16;
const double kNotchInset = 14;
const double kCornerRadius = 6;
const double kBlockMinHeight = 36;

class _SingleBlock extends StatelessWidget {
  const _SingleBlock({required this.node, required this.spec});

  final BlockNode node;
  final BlockSpec spec;

  @override
  Widget build(BuildContext context) {
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
            for (final p in pieces) _renderPiece(p, node, spec),
          ],
        ),
      ),
    );

    Widget body = CustomPaint(
      painter: _BlockShapePainter(color: color, shape: spec.shape),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: kBlockMinHeight),
        child: inner,
      ),
    );

    if (spec.shape == BlockShape.cBlock && spec.mouths.isNotEmpty) {
      body = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          body,
          for (final m in spec.mouths)
            _MouthRender(
              color: color,
              label: m.name,
              children: node.mouthStacks[m.name] ?? const [],
            ),
        ],
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: kNotchHeight),
      child: body,
    );
  }
}

Widget _renderPiece(_Piece p, BlockNode node, BlockSpec spec) {
  if (p.kind == _PieceKind.text) return Text(p.value);
  // Reference: prefer a spec field, then a slot, otherwise plain text.
  for (final f in spec.fields) {
    if (f.name == p.value) {
      final value = node.fieldValues[p.value] ?? f.defaultValue;
      return _FieldChip(field: f, value: value);
    }
  }
  for (final s in spec.slots) {
    if (s.name == p.value) {
      final child = node.slotChildren[p.value];
      if (child == null) return _SlotPlaceholder(type: s.accepts);
      return BlockWidget(node: child);
    }
  }
  return Text('%${p.value}');
}

class _FieldChip extends StatelessWidget {
  const _FieldChip({required this.field, required this.value});
  final BlockFieldSpec field;
  final String value;

  @override
  Widget build(BuildContext context) {
    final display = value.isEmpty ? field.placeholder : value;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
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
    );
  }
}

class _SlotPlaceholder extends StatelessWidget {
  const _SlotPlaceholder({required this.type});
  final BlockType type;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.18),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        type == BlockType.any ? '⋯' : type.id,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: 11,
        ),
      ),
    );
  }
}

class _MouthRender extends StatelessWidget {
  const _MouthRender({
    required this.color,
    required this.label,
    required this.children,
  });

  final Color color;
  final String label;
  final List<BlockNode> children;

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
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ),
          if (children.isEmpty)
            Container(
              width: 80,
              height: 14,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
            )
          else
            for (final c in children) BlockWidget(node: c),
        ],
      ),
    );
  }
}

class _MissingSpec extends StatelessWidget {
  const _MissingSpec({required this.specId});
  final String specId;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        'unknown block: $specId',
        style: TextStyle(color: Colors.red.shade900, fontSize: 11),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Painter: notched jigsaw outline
// ---------------------------------------------------------------------------

class _BlockShapePainter extends CustomPainter {
  _BlockShapePainter({required this.color, required this.shape});

  final Color color;
  final BlockShape shape;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final path = Path();
    // Top edge with optional top notch
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

    // Bottom edge with optional bottom notch
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
  bool shouldRepaint(covariant _BlockShapePainter old) =>
      old.color != color || old.shape != shape;
}

// ---------------------------------------------------------------------------
// Template parser: splits "set %name to %value" into ["set ", FIELD(name),
// " to ", SLOT(value)] — fields and slots are distinguished by whether the
// referenced name exists in spec.fields vs spec.slots; the parser is shared.
// ---------------------------------------------------------------------------

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
