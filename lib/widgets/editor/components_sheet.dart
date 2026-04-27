import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../state/editor_provider.dart';

/// Bottom sheet that lists the user's saved components and provides:
/// - "Save selection as component" — clones the currently selected element
///   subtree and stores it on the project.
/// - Tap a saved component → insert into the current drop parent.
/// - Long press → delete.
class ComponentsSheet extends StatelessWidget {
  const ComponentsSheet({super.key});

  static Future<void> show(BuildContext context) async {
    final provider = Provider.of<EditorProvider>(context, listen: false);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const ComponentsSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ed = context.watch<EditorProvider>();
    final hasSelection = ed.selectedElementId != null &&
        ed.selectedElementId != ed.activePage.root.id;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.widgets_outlined, color: cs.primary),
              title: Text(l10n.components,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              trailing: TextButton.icon(
                icon: const Icon(Icons.add, size: 18),
                onPressed: hasSelection
                    ? () => _saveAsComponent(context, ed)
                    : null,
                label: Text(l10n.saveAsComponent),
              ),
            ),
            const Divider(height: 1),
            if (ed.project.components.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  l10n.noComponentsYet,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: ed.project.components.length,
                  itemBuilder: (context, i) {
                    final c = ed.project.components[i];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: cs.primaryContainer,
                        child: Icon(Icons.widgets, color: cs.primary, size: 18),
                      ),
                      title: Text(c.name),
                      subtitle: Text(c.root.type.id,
                          style: TextStyle(
                              color: cs.onSurfaceVariant, fontSize: 12)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => ed.deleteComponent(c.id),
                      ),
                      onTap: () {
                        ed.insertComponent(c);
                        Navigator.of(context).pop();
                      },
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveAsComponent(BuildContext context, EditorProvider ed) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveAsComponent),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.componentName,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null) return;
    final saved = ed.saveSelectionAsComponent(name);
    if (saved != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.componentSaved)),
      );
    }
  }
}
