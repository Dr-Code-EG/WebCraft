import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

class TreeView extends StatelessWidget {
  const TreeView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Consumer<EditorProvider>(
      builder: (context, ed, _) {
        return ListView(
          padding: const EdgeInsets.all(8),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Row(
                children: [
                  Icon(Icons.account_tree_outlined,
                      color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Text(l10n.tree,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 16)),
                ],
              ),
            ),
            _Node(node: ed.activePage.root, depth: 0),
          ],
        );
      },
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.node, required this.depth});

  final ElementNode node;
  final int depth;

  @override
  Widget build(BuildContext context) {
    final ed = context.watch<EditorProvider>();
    final selected = ed.selectedElementId == node.id;
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: selected
              ? cs.primaryContainer.withOpacity(0.6)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => ed.select(node.id),
            child: Padding(
              padding: EdgeInsetsDirectional.only(
                start: 8.0 + depth * 16,
                end: 8,
                top: 8,
                bottom: 8,
              ),
              child: Row(
                children: [
                  Icon(_iconFor(node.type), size: 18, color: cs.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      node.type.id,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 14),
                    ),
                  ),
                  if (node.props['text']?.isNotEmpty == true)
                    Flexible(
                      child: Text(
                        '"${node.props['text']}"',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        for (final c in node.children) _Node(node: c, depth: depth + 1),
      ],
    );
  }

  IconData _iconFor(ElementType t) {
    switch (t) {
      case ElementType.container:
        return Icons.crop_din;
      case ElementType.row:
        return Icons.view_week_outlined;
      case ElementType.column:
        return Icons.view_agenda_outlined;
      case ElementType.heading:
        return Icons.title;
      case ElementType.paragraph:
        return Icons.notes;
      case ElementType.text:
        return Icons.short_text;
      case ElementType.button:
        return Icons.smart_button;
      case ElementType.image:
        return Icons.image_outlined;
      case ElementType.input:
        return Icons.input;
      case ElementType.textarea:
        return Icons.notes_outlined;
      case ElementType.form:
        return Icons.dynamic_form_outlined;
      case ElementType.link:
        return Icons.link;
      case ElementType.divider:
        return Icons.horizontal_rule;
      case ElementType.spacer:
        return Icons.space_bar;
      case ElementType.card:
        return Icons.dashboard_outlined;
      case ElementType.list:
        return Icons.list;
      case ElementType.video:
        return Icons.videocam_outlined;
    }
  }
}
