import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/project.dart';
import '../../state/editor_provider.dart';

/// In-app theme editor: a list of CSS custom properties stored on the
/// project, edited as `--name`/`value` pairs and emitted as a `:root { ... }`
/// block at the top of the generated stylesheet.
class ThemeEditorDialog extends StatefulWidget {
  const ThemeEditorDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final provider = Provider.of<EditorProvider>(context, listen: false);
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const ThemeEditorDialog(),
      ),
    );
  }

  @override
  State<ThemeEditorDialog> createState() => _ThemeEditorDialogState();
}

class _ThemeEditorDialogState extends State<ThemeEditorDialog> {
  late Map<String, TextEditingController> _controllers;
  late EditorProvider _ed;

  @override
  void initState() {
    super.initState();
    _ed = Provider.of<EditorProvider>(context, listen: false);
    _controllers = {
      for (final e in _ed.project.themeVars.entries)
        e.key: TextEditingController(text: e.value),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final out = <String, String>{};
    for (final e in _controllers.entries) {
      final v = e.value.text.trim();
      if (v.isNotEmpty) out[e.key] = v;
    }
    _ed.setThemeVars(out);
    Navigator.of(context).pop();
  }

  void _resetDefaults() {
    setState(() {
      for (final c in _controllers.values) {
        c.dispose();
      }
      _controllers = {
        for (final e in kDefaultThemeVars.entries)
          e.key: TextEditingController(text: e.value),
      };
    });
  }

  void _addVar() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New CSS variable'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '--my-token',
            prefixText: '--',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final raw = controller.text.trim();
              if (raw.isEmpty) {
                Navigator.of(ctx).pop(null);
                return;
              }
              final cleaned = raw.startsWith('--') ? raw : '--$raw';
              Navigator.of(ctx).pop(cleaned);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (name == null || _controllers.containsKey(name)) return;
    setState(() {
      _controllers[name] = TextEditingController();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.palette_outlined, color: cs.primary),
          const SizedBox(width: 8),
          Text(l10n.themeEditor),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.themeEditorHint,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final entry in _controllers.entries.toList())
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120,
                              child: Text(
                                entry.key,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: entry.value,
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: l10n.delete,
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () {
                                setState(() {
                                  _controllers.remove(entry.key)?.dispose();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.add),
                onPressed: _addVar,
                label: Text(l10n.themeEditorAdd),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _resetDefaults,
          child: Text(l10n.themeEditorReset),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}

/// Free-form CSS editor — value is appended verbatim to the generated
/// stylesheet after the theme block and the base reset.
class CustomCssDialog extends StatefulWidget {
  const CustomCssDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final provider = Provider.of<EditorProvider>(context, listen: false);
    await showDialog<void>(
      context: context,
      builder: (_) => ChangeNotifierProvider.value(
        value: provider,
        child: const CustomCssDialog(),
      ),
    );
  }

  @override
  State<CustomCssDialog> createState() => _CustomCssDialogState();
}

class _CustomCssDialogState extends State<CustomCssDialog> {
  late TextEditingController _controller;
  late EditorProvider _ed;

  @override
  void initState() {
    super.initState();
    _ed = Provider.of<EditorProvider>(context, listen: false);
    _controller = TextEditingController(text: _ed.project.customCss);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.code, color: cs.primary),
          const SizedBox(width: 8),
          Text(l10n.customCss),
        ],
      ),
      content: SizedBox(
        width: 520,
        height: 360,
        child: TextField(
          controller: _controller,
          maxLines: null,
          expands: true,
          style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: l10n.customCssHint,
            alignLabelWithHint: true,
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () {
            _ed.setCustomCss(_controller.text);
            Navigator.of(context).pop();
          },
          child: Text(l10n.save),
        ),
      ],
    );
  }
}
