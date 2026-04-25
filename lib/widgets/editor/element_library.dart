import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

/// Sidebar listing draggable HTML element kinds, grouped by category.
class ElementLibrary extends StatelessWidget {
  const ElementLibrary({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLowest,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 16, 12, 24),
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, right: 4, bottom: 8),
            child: Row(
              children: [
                Icon(Icons.widgets_rounded, color: cs.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  l10n.elements,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.dragToCanvas,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          _section(context, l10n.categoryLayout, _layoutItems(l10n)),
          _section(context, l10n.categoryContent, _contentItems(l10n)),
          _section(context, l10n.categoryForm, _formItems(l10n)),
          _section(context, l10n.categoryMisc, _miscItems(l10n)),
        ],
      ),
    );
  }

  Widget _section(
      BuildContext context, String title, List<_LibraryItem> items) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
            child: Text(
              title,
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.6,
              ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((it) => _DraggableTile(item: it)).toList(),
          ),
        ],
      ),
    );
  }

  List<_LibraryItem> _layoutItems(AppLocalizations l10n) => [
        _LibraryItem(
            ElementType.container, Icons.crop_din, l10n.elementContainer),
        _LibraryItem(
            ElementType.row, Icons.view_week_outlined, l10n.elementRow),
        _LibraryItem(
            ElementType.column, Icons.view_agenda_outlined, l10n.elementColumn),
        _LibraryItem(
            ElementType.card, Icons.dashboard_outlined, l10n.elementCard),
      ];

  List<_LibraryItem> _contentItems(AppLocalizations l10n) => [
        _LibraryItem(ElementType.heading, Icons.title, l10n.elementHeading),
        _LibraryItem(ElementType.paragraph, Icons.notes, l10n.elementParagraph),
        _LibraryItem(ElementType.text, Icons.short_text, l10n.elementText),
        _LibraryItem(
            ElementType.image, Icons.image_outlined, l10n.elementImage),
        _LibraryItem(ElementType.link, Icons.link, l10n.elementLink),
        _LibraryItem(ElementType.list, Icons.list, l10n.elementList),
        _LibraryItem(
            ElementType.video, Icons.videocam_outlined, l10n.elementVideo),
      ];

  List<_LibraryItem> _formItems(AppLocalizations l10n) => [
        _LibraryItem(
            ElementType.button, Icons.smart_button, l10n.elementButton),
        _LibraryItem(ElementType.input, Icons.input, l10n.elementInput),
        _LibraryItem(
            ElementType.textarea, Icons.notes_outlined, l10n.elementTextarea),
        _LibraryItem(
            ElementType.form, Icons.dynamic_form_outlined, l10n.elementForm),
      ];

  List<_LibraryItem> _miscItems(AppLocalizations l10n) => [
        _LibraryItem(
            ElementType.divider, Icons.horizontal_rule, l10n.elementDivider),
        _LibraryItem(ElementType.spacer, Icons.space_bar, l10n.elementSpacer),
      ];
}

class _LibraryItem {
  _LibraryItem(this.type, this.icon, this.label);
  final ElementType type;
  final IconData icon;
  final String label;
}

class _DraggableTile extends StatelessWidget {
  const _DraggableTile({required this.item});
  final _LibraryItem item;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tile = SizedBox(
      width: 92,
      height: 88,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: cs.outlineVariant.withOpacity(0.6)),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Provider.of<EditorProvider>(context, listen: false)
                .addElement(item.type);
          },
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(item.icon, color: cs.primary, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  item.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return LongPressDraggable<ElementType>(
      data: item.type,
      feedback: Material(
        color: Colors.transparent,
        child: Opacity(opacity: 0.85, child: tile),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: tile),
      child: tile,
    );
  }
}
