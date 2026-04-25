import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

/// Center of the editor: shows a phone-sized canvas that visually
/// approximates the generated HTML for the active page.
class CanvasView extends StatelessWidget {
  const CanvasView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerHigh,
      child: Column(
        children: [
          _CanvasToolbar(),
          Expanded(
            child: Consumer<EditorProvider>(
              builder: (context, ed, _) {
                final root = ed.activePage.root;
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 24,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: _ElementWidget(
                              node: root,
                              isRoot: true,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Text(
                        l10n.dragToCanvas,
                        style:
                            TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CanvasToolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Consumer<EditorProvider>(
      builder: (context, ed, _) {
        final hasSelection = ed.selectedElementId != null &&
            ed.selectedElementId != ed.activePage.root.id;
        return Container(
          height: 44,
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: cs.surface,
            border: Border(bottom: BorderSide(color: cs.outlineVariant)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Move up',
                onPressed: hasSelection
                    ? () => ed.moveElementUp(ed.selectedElementId!)
                    : null,
                icon: const Icon(Icons.arrow_upward),
                iconSize: 20,
              ),
              IconButton(
                tooltip: 'Move down',
                onPressed: hasSelection
                    ? () => ed.moveElementDown(ed.selectedElementId!)
                    : null,
                icon: const Icon(Icons.arrow_downward),
                iconSize: 20,
              ),
              IconButton(
                tooltip: 'Duplicate',
                onPressed: hasSelection
                    ? () => ed.duplicateElement(ed.selectedElementId!)
                    : null,
                icon: const Icon(Icons.content_copy_outlined),
                iconSize: 20,
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: hasSelection
                    ? () => ed.deleteElement(ed.selectedElementId!)
                    : null,
                icon: const Icon(Icons.delete_outline),
                iconSize: 20,
              ),
              const Spacer(),
              if (ed.selectedElementId != null)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: Text(
                    _label(context, ed.selectedElement?.type),
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _label(BuildContext context, ElementType? t) {
    if (t == null) return '';
    final l10n = AppLocalizations.of(context)!;
    switch (t) {
      case ElementType.container:
        return l10n.elementContainer;
      case ElementType.row:
        return l10n.elementRow;
      case ElementType.column:
        return l10n.elementColumn;
      case ElementType.heading:
        return l10n.elementHeading;
      case ElementType.paragraph:
        return l10n.elementParagraph;
      case ElementType.text:
        return l10n.elementText;
      case ElementType.button:
        return l10n.elementButton;
      case ElementType.image:
        return l10n.elementImage;
      case ElementType.input:
        return l10n.elementInput;
      case ElementType.textarea:
        return l10n.elementTextarea;
      case ElementType.form:
        return l10n.elementForm;
      case ElementType.link:
        return l10n.elementLink;
      case ElementType.divider:
        return l10n.elementDivider;
      case ElementType.spacer:
        return l10n.elementSpacer;
      case ElementType.card:
        return l10n.elementCard;
      case ElementType.list:
        return l10n.elementList;
      case ElementType.video:
        return l10n.elementVideo;
    }
  }
}

class _ElementWidget extends StatelessWidget {
  const _ElementWidget({required this.node, this.isRoot = false});

  final ElementNode node;
  final bool isRoot;

  @override
  Widget build(BuildContext context) {
    final ed = context.watch<EditorProvider>();
    final selected = ed.selectedElementId == node.id;
    final accepts = node.type.acceptsChildren;

    final inner = _renderInner(context, node);

    Widget wrapped = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => ed.select(node.id),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        margin:
            isRoot ? EdgeInsets.zero : const EdgeInsets.symmetric(vertical: 2),
        child: inner,
      ),
    );

    if (accepts) {
      wrapped = DragTarget<ElementType>(
        onWillAcceptWithDetails: (_) => true,
        onAcceptWithDetails: (details) {
          ed.addElementInside(details.data, node.id);
        },
        builder: (context, candidate, rejected) {
          final hovering = candidate.isNotEmpty;
          return Container(
            decoration: BoxDecoration(
              color: hovering
                  ? Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.2)
                  : null,
              borderRadius: BorderRadius.circular(4),
            ),
            child: wrapped,
          );
        },
      );
    }

    return wrapped;
  }

  Widget _renderInner(BuildContext context, ElementNode node) {
    final style = node.style;
    final padding = _edgeInsets(style['padding']);
    final margin = _edgeInsets(style['margin']);
    final bg = _color(style['background']);
    final radius = _radius(style['border-radius']);
    final color = _color(style['color']);
    final fontSize = _double(style['font-size']);
    final fontWeight = _fontWeight(style['font-weight']);
    final textAlign = _textAlign(style['text-align']);
    final width = _double(style['width']) ?? _double(style['max-width']);
    final height = _double(style['height']);

    Widget content;

    switch (node.type) {
      case ElementType.heading:
      case ElementType.paragraph:
      case ElementType.text:
        content = Text(
          node.props['text'] ?? '',
          textAlign: textAlign,
          style: TextStyle(
            color: color,
            fontSize: fontSize ?? (node.type == ElementType.heading ? 24 : 16),
            fontWeight: fontWeight ??
                (node.type == ElementType.heading
                    ? FontWeight.w700
                    : FontWeight.w400),
            height: 1.4,
          ),
        );
        break;
      case ElementType.button:
        content = Center(
          child: Text(
            node.props['text'] ?? 'Button',
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: fontSize ?? 14,
              fontWeight: fontWeight ?? FontWeight.w600,
            ),
          ),
        );
        break;
      case ElementType.image:
        final src = node.props['src'] ?? '';
        if (src.startsWith('http')) {
          content = Image.network(
            src,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _imagePlaceholder(),
            loadingBuilder: (_, child, p) =>
                p == null ? child : _imagePlaceholder(loading: true),
          );
        } else {
          content = _imagePlaceholder();
        }
        break;
      case ElementType.input:
        content = TextField(
          enabled: false,
          decoration: InputDecoration(
            isDense: true,
            hintText: node.props['placeholder'] ?? '',
            border: InputBorder.none,
          ),
        );
        break;
      case ElementType.textarea:
        content = TextField(
          enabled: false,
          maxLines: int.tryParse(node.props['rows'] ?? '4') ?? 4,
          decoration: InputDecoration(
            isDense: true,
            hintText: node.props['placeholder'] ?? '',
            border: InputBorder.none,
          ),
        );
        break;
      case ElementType.link:
        if (node.children.isEmpty) {
          content = Text(
            node.props['text'] ?? 'link',
            style: TextStyle(
              color: color ?? const Color(0xFF2563EB),
              decoration: TextDecoration.underline,
              fontSize: fontSize ?? 14,
            ),
          );
        } else {
          content = _childrenColumn(node);
        }
        break;
      case ElementType.divider:
        content = const Divider(height: 1);
        break;
      case ElementType.spacer:
        content =
            SizedBox(height: height ?? 32, width: width ?? double.infinity);
        break;
      case ElementType.list:
        final ordered = (node.props['ordered'] ?? 'false') == 'true';
        content = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < node.children.length; i++)
              Padding(
                padding: const EdgeInsetsDirectional.only(
                    start: 16, top: 2, bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ordered ? '${i + 1}. ' : '• ',
                        style: TextStyle(color: color)),
                    Expanded(child: _ElementWidget(node: node.children[i])),
                  ],
                ),
              ),
          ],
        );
        break;
      case ElementType.video:
        content = Container(
          height: 160,
          color: Colors.black87,
          child: const Center(
            child:
                Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
          ),
        );
        break;
      case ElementType.container:
      case ElementType.row:
      case ElementType.column:
      case ElementType.card:
      case ElementType.form:
        content = _layoutChildren(node);
        break;
    }

    final container = Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: radius,
        border: _border(style['border']),
        boxShadow: _shadow(style['box-shadow']),
      ),
      child: content,
    );

    return container;
  }

  Widget _layoutChildren(ElementNode node) {
    final children = node.children;
    if (children.isEmpty) {
      return _DropPlaceholder(node: node);
    }
    final isRow =
        node.type == ElementType.row || node.style['flex-direction'] == 'row';
    final gap = _double(node.style['gap']) ?? 8;

    if (isRow) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: _justifyToMain(node.style['justify-content']),
        children: _interleave(
          children
              .map((c) => Flexible(child: _ElementWidget(node: c)))
              .toList(),
          gap,
          isRow: true,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: _interleave(
        children.map((c) => _ElementWidget(node: c)).toList(),
        gap,
        isRow: false,
      ),
    );
  }

  Widget _childrenColumn(ElementNode node) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: node.children.map((c) => _ElementWidget(node: c)).toList(),
    );
  }

  static List<Widget> _interleave(List<Widget> items, double gap,
      {required bool isRow}) {
    if (items.length <= 1) return items;
    final out = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      out.add(items[i]);
      if (i < items.length - 1) {
        out.add(SizedBox(width: isRow ? gap : 0, height: isRow ? 0 : gap));
      }
    }
    return out;
  }

  static Widget _imagePlaceholder({bool loading = false}) {
    return Container(
      height: 140,
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: loading
          ? const CircularProgressIndicator(strokeWidth: 2)
          : const Icon(Icons.image_outlined,
              size: 40, color: Color(0xFF6B7280)),
    );
  }

  // ----- CSS -> Flutter parsers (tolerant best-effort) -----

  static EdgeInsetsGeometry? _edgeInsets(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.trim().split(RegExp(r'\s+'));
    final nums = parts.map(_parseLen).toList();
    switch (nums.length) {
      case 1:
        return EdgeInsets.all(nums[0]);
      case 2:
        return EdgeInsets.symmetric(vertical: nums[0], horizontal: nums[1]);
      case 3:
        return EdgeInsets.fromLTRB(nums[1], nums[0], nums[1], nums[2]);
      case 4:
        return EdgeInsets.fromLTRB(nums[3], nums[0], nums[1], nums[2]);
      default:
        return null;
    }
  }

  static double _parseLen(String s) {
    final m = RegExp(r'(-?\d+(?:\.\d+)?)').firstMatch(s);
    if (m == null) return 0;
    return double.tryParse(m.group(1)!) ?? 0;
  }

  static Color? _color(String? value) {
    if (value == null) return null;
    final v = value.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('#')) {
      var hex = v.substring(1);
      if (hex.length == 3) {
        hex = hex.split('').map((c) => '$c$c').join();
      }
      if (hex.length == 6) {
        final n = int.tryParse(hex, radix: 16);
        if (n != null) return Color(0xFF000000 | n);
      }
      if (hex.length == 8) {
        final n = int.tryParse(hex, radix: 16);
        if (n != null) return Color(n);
      }
    }
    if (v.startsWith('rgb')) {
      final m = RegExp(r'rgba?\(([^)]+)\)').firstMatch(v);
      if (m != null) {
        final parts = m.group(1)!.split(',').map((e) => e.trim()).toList();
        if (parts.length >= 3) {
          final r = int.tryParse(parts[0]) ?? 0;
          final g = int.tryParse(parts[1]) ?? 0;
          final b = int.tryParse(parts[2]) ?? 0;
          final a = parts.length >= 4
              ? ((double.tryParse(parts[3]) ?? 1) * 255).round()
              : 255;
          return Color.fromARGB(a, r, g, b);
        }
      }
    }
    return null;
  }

  static BorderRadius? _radius(String? value) {
    if (value == null) return null;
    final n = _parseLen(value);
    return BorderRadius.circular(n);
  }

  static double? _double(String? value) {
    if (value == null) return null;
    return _parseLen(value) > 0 ? _parseLen(value) : null;
  }

  static FontWeight? _fontWeight(String? value) {
    if (value == null) return null;
    final v = value.trim().toLowerCase();
    if (v == 'bold' || v == '700' || v == '600' || v == '800') {
      return FontWeight.w700;
    }
    if (v == '500') return FontWeight.w500;
    if (v == '400' || v == 'normal') return FontWeight.w400;
    if (v == '300') return FontWeight.w300;
    return null;
  }

  static TextAlign? _textAlign(String? value) {
    switch (value) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      case 'left':
        return TextAlign.left;
      case 'justify':
        return TextAlign.justify;
    }
    return null;
  }

  static MainAxisAlignment _justifyToMain(String? v) {
    switch (v) {
      case 'center':
        return MainAxisAlignment.center;
      case 'flex-end':
      case 'end':
        return MainAxisAlignment.end;
      case 'space-between':
        return MainAxisAlignment.spaceBetween;
      case 'space-around':
        return MainAxisAlignment.spaceAround;
      case 'space-evenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  static Border? _border(String? value) {
    if (value == null || value.trim().isEmpty || value.trim() == 'none') {
      return null;
    }
    final m = RegExp(r'(\d+(?:\.\d+)?)px\s+(solid|dashed|dotted)\s+(\S+)')
        .firstMatch(value);
    if (m == null) return null;
    final w = double.tryParse(m.group(1)!) ?? 1;
    final c = _color(m.group(3)) ?? const Color(0xFFD1D5DB);
    return Border.all(color: c, width: w);
  }

  static List<BoxShadow>? _shadow(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return [
      BoxShadow(
        color: Colors.black.withOpacity(0.08),
        blurRadius: 6,
        offset: const Offset(0, 2),
      ),
    ];
  }
}

class _DropPlaceholder extends StatelessWidget {
  const _DropPlaceholder({required this.node});
  final ElementNode node;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cs.outlineVariant,
          style: BorderStyle.solid,
        ),
      ),
      child: Text(
        AppLocalizations.of(context)!.dragToCanvas,
        style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
      ),
    );
  }
}
