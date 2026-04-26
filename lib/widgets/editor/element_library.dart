import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

/// Right-hand sidebar listing draggable HTML element kinds, stacked
/// vertically (Sketchware-style). Each row is a long-press draggable; a
/// short tap inserts the element into the currently-selected container.
class ElementLibrary extends StatelessWidget {
  const ElementLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final sections = _buildSections(l10n);

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
                  _SectionHeader(title: section.title),
                  for (final item in section.items) _DraggableRow(item: item),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_Section> _buildSections(AppLocalizations l10n) => [
        _Section(
          title: l10n.categoryLayout,
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
  _Section({required this.title, required this.items});
  final String title;
  final List<_LibraryItem> items;
}

class _LibraryItem {
  _LibraryItem(this.type, this.icon, this.label);
  final ElementType type;
  final IconData icon;
  final String label;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w800,
          fontSize: 10.5,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _DraggableRow extends StatelessWidget {
  const _DraggableRow({required this.item});
  final _LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final visual = SizedBox(
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Provider.of<EditorProvider>(context, listen: false)
                .addElement(item.type);
          },
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 8),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.drag_indicator_rounded,
                  size: 18,
                  color: cs.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: 200,
        child: Material(
          elevation: 6,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.primary.withOpacity(0.4)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(item.icon, color: cs.primary, size: 20),
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

    return Draggable<ElementType>(
      data: item.type,
      feedback: feedback,
      childWhenDragging: Opacity(opacity: 0.4, child: visual),
      child: visual,
    );
  }
}
