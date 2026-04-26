import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

enum ElementLibraryMode {
  /// Wide rail with icon + label + drag handle.
  full,

  /// Narrow rail with icon-only tiles, one per row, color-coded by section.
  compact,
}

/// Right-hand sidebar listing draggable HTML element kinds. Has two layouts:
/// - [ElementLibraryMode.full] (≥ 200 px wide): icon + label + drag handle
/// - [ElementLibraryMode.compact] (≈ 56-72 px): icon only, color-coded by
///   category. Used on phones where horizontal real estate is precious.
class ElementLibrary extends StatelessWidget {
  const ElementLibrary({super.key, this.mode = ElementLibraryMode.full});

  final ElementLibraryMode mode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final sections = _buildSections(l10n, cs);

    if (mode == ElementLibraryMode.compact) {
      return _CompactRail(sections: sections);
    }
    return _FullRail(sections: sections, l10n: l10n);
  }

  List<_Section> _buildSections(AppLocalizations l10n, ColorScheme cs) => [
        _Section(
          title: l10n.categoryLayout,
          color: const Color(0xFF2563EB),
          items: [
            _LibraryItem(
                ElementType.container, Icons.crop_din, l10n.elementContainer),
            _LibraryItem(
                ElementType.row, Icons.view_week_outlined, l10n.elementRow),
            _LibraryItem(ElementType.column, Icons.view_agenda_outlined,
                l10n.elementColumn),
            _LibraryItem(
                ElementType.card, Icons.dashboard_outlined, l10n.elementCard),
          ],
        ),
        _Section(
          title: l10n.categoryContent,
          color: const Color(0xFF7C3AED),
          items: [
            _LibraryItem(ElementType.heading, Icons.title, l10n.elementHeading),
            _LibraryItem(
                ElementType.paragraph, Icons.notes, l10n.elementParagraph),
            _LibraryItem(ElementType.text, Icons.short_text, l10n.elementText),
            _LibraryItem(
                ElementType.image, Icons.image_outlined, l10n.elementImage),
            _LibraryItem(ElementType.link, Icons.link, l10n.elementLink),
            _LibraryItem(ElementType.list, Icons.list, l10n.elementList),
            _LibraryItem(
                ElementType.video, Icons.videocam_outlined, l10n.elementVideo),
          ],
        ),
        _Section(
          title: l10n.categoryForm,
          color: const Color(0xFF16A34A),
          items: [
            _LibraryItem(
                ElementType.button, Icons.smart_button, l10n.elementButton),
            _LibraryItem(ElementType.input, Icons.input, l10n.elementInput),
            _LibraryItem(ElementType.textarea, Icons.notes_outlined,
                l10n.elementTextarea),
            _LibraryItem(ElementType.form, Icons.dynamic_form_outlined,
                l10n.elementForm),
          ],
        ),
        _Section(
          title: l10n.categoryMisc,
          color: const Color(0xFFEA580C),
          items: [
            _LibraryItem(ElementType.divider, Icons.horizontal_rule,
                l10n.elementDivider),
            _LibraryItem(
                ElementType.spacer, Icons.space_bar, l10n.elementSpacer),
          ],
        ),
      ];
}

class _Section {
  _Section({required this.title, required this.color, required this.items});
  final String title;
  final Color color;
  final List<_LibraryItem> items;
}

class _LibraryItem {
  _LibraryItem(this.type, this.icon, this.label);
  final ElementType type;
  final IconData icon;
  final String label;
}

// ---------- Full rail (tablet/desktop) ----------

class _FullRail extends StatelessWidget {
  const _FullRail({required this.sections, required this.l10n});
  final List<_Section> sections;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    l10n.elements,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                  child: Text(
                    l10n.dragToCanvas,
                    style: TextStyle(
                      color: cs.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                  ),
                ),
                for (final section in sections) ...[
                  _SectionHeader(title: section.title, color: section.color),
                  for (final item in section.items)
                    _DraggableRow(item: item, accent: section.color),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.color});
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _DraggableRow extends StatelessWidget {
  const _DraggableRow({required this.item, required this.accent});
  final _LibraryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final visual = SizedBox(
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<EditorProvider>(context, listen: false)
                .addElement(item.type);
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: accent, size: 19),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 16,
                  color: cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final feedback = _DragFeedback(item: item, accent: accent);

    return Draggable<ElementType>(
      data: item.type,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.4, child: visual),
      child: visual,
    );
  }
}

// ---------- Compact rail (phone) ----------

class _CompactRail extends StatelessWidget {
  const _CompactRail({required this.sections});
  final List<_Section> sections;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        children: [
          Container(
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
              ),
            ),
            child: Icon(Icons.widgets_rounded, color: cs.primary, size: 18),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 4),
              children: [
                for (final section in sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 6, 0, 2),
                    child: Center(
                      child: Container(
                        width: 22,
                        height: 3,
                        decoration: BoxDecoration(
                          color: section.color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                  for (final item in section.items)
                    _CompactTile(item: item, accent: section.color),
                ],
                const SizedBox(height: 6),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactTile extends StatelessWidget {
  const _CompactTile({required this.item, required this.accent});
  final _LibraryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final visual = Tooltip(
      message: item.label,
      preferBelow: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () {
              Provider.of<EditorProvider>(context, listen: false)
                  .addElement(item.type);
            },
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: accent.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: accent.withOpacity(0.30),
                  width: 0.8,
                ),
              ),
              alignment: Alignment.center,
              child: Icon(item.icon, color: accent, size: 20),
            ),
          ),
        ),
      ),
    );

    return Draggable<ElementType>(
      data: item.type,
      feedback: _DragFeedback(item: item, accent: accent),
      childWhenDragging: Opacity(opacity: 0.35, child: visual),
      child: visual,
    );
  }
}

class _DragFeedback extends StatelessWidget {
  const _DragFeedback({required this.item, required this.accent});
  final _LibraryItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 200,
        child: Material(
          elevation: 8,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: accent, width: 1.2),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: accent, size: 18),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
