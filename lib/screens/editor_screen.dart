import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/project.dart';
import '../services/export_service.dart';
import '../state/editor_provider.dart';
import '../state/projects_provider.dart';
import '../widgets/editor/canvas_view.dart';
import '../widgets/editor/components_sheet.dart';
import '../widgets/editor/element_library.dart';
import '../widgets/editor/properties_panel.dart';
import '../widgets/editor/theme_editor_dialog.dart';
import '../widgets/editor/tree_view.dart';
import 'preview_screen.dart';

/// Sketchware-inspired editor: canvas in the center, vertical element
/// library on the right, and a horizontal properties strip pinned to the
/// bottom that opens dialogs for editing.
class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.project});

  final Project project;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final EditorProvider _editor;

  @override
  void initState() {
    super.initState();
    _editor = EditorProvider(widget.project);
    _editor.addListener(_autosave);
  }

  @override
  void dispose() {
    _editor.removeListener(_autosave);
    _saveNow(showSnack: false);
    super.dispose();
  }

  Future<void> _autosave() async {
    if (!_editor.dirty) return;
    final prov = Provider.of<ProjectsProvider>(context, listen: false);
    await prov.save(widget.project);
    _editor.markSaved();
  }

  Future<void> _saveNow({bool showSnack = true}) async {
    if (!mounted) return;
    final prov = Provider.of<ProjectsProvider>(context, listen: false);
    await prov.save(widget.project);
    _editor.markSaved();
    if (showSnack && mounted) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.savedConfirmation)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _editor,
      child: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 900;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                widget.project.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              actions: [
                Consumer<EditorProvider>(
                  builder: (context, ed, _) => IconButton(
                    tooltip: l10n.undo,
                    icon: const Icon(Icons.undo_rounded),
                    onPressed: ed.canUndo ? ed.undo : null,
                  ),
                ),
                Consumer<EditorProvider>(
                  builder: (context, ed, _) => IconButton(
                    tooltip: l10n.redo,
                    icon: const Icon(Icons.redo_rounded),
                    onPressed: ed.canRedo ? ed.redo : null,
                  ),
                ),
                IconButton(
                  tooltip: l10n.newPage,
                  icon: const Icon(Icons.note_add_outlined),
                  onPressed: () => _addPage(context),
                ),
                IconButton(
                  tooltip: l10n.tree,
                  icon: const Icon(Icons.account_tree_outlined),
                  onPressed: () => _openTreeSheet(context),
                ),
                IconButton(
                  tooltip: l10n.components,
                  icon: const Icon(Icons.widgets_outlined),
                  onPressed: () => ComponentsSheet.show(context),
                ),
                IconButton(
                  tooltip: l10n.preview,
                  icon: const Icon(Icons.play_arrow_rounded),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => PreviewScreen(project: widget.project),
                    ));
                  },
                ),
                PopupMenuButton<String>(
                  tooltip: l10n.more,
                  icon: const Icon(Icons.more_vert),
                  onSelected: (key) async {
                    switch (key) {
                      case 'theme':
                        await ThemeEditorDialog.show(context);
                        break;
                      case 'css':
                        await CustomCssDialog.show(context);
                        break;
                      case 'exportZip':
                        await _exportZip(context, ExportTarget.generic);
                        break;
                      case 'exportGh':
                        await _exportZip(context, ExportTarget.githubPages);
                        break;
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'theme',
                      child: Row(children: [
                        const Icon(Icons.palette_outlined, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.themeEditor),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'css',
                      child: Row(children: [
                        const Icon(Icons.code, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.customCss),
                      ]),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem(
                      value: 'exportZip',
                      child: Row(children: [
                        const Icon(Icons.ios_share_rounded, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.exportZip),
                      ]),
                    ),
                    PopupMenuItem(
                      value: 'exportGh',
                      child: Row(children: [
                        const Icon(Icons.public, size: 18),
                        const SizedBox(width: 8),
                        Text(l10n.exportGithubPages),
                      ]),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              top: false,
              child: wide ? _wideLayout() : _phoneLayout(),
            ),
          );
        },
      ),
    );
  }

  /// Tablet / desktop layout: canvas + properties stacked on the left,
  /// full-width element library pinned to the right (icon + label).
  Widget _wideLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: CanvasView()),
              Divider(height: 1, thickness: 1),
              PropertiesPanel(),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        SizedBox(
          width: 240,
          child: ElementLibrary(mode: ElementLibraryMode.full),
        ),
      ],
    );
  }

  /// Phone layout: canvas + bottom properties + a slim icon-only
  /// element rail anchored to the right edge (Sketchware-style).
  Widget _phoneLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            children: [
              Expanded(child: CanvasView()),
              Divider(height: 1, thickness: 1),
              PropertiesPanel(),
            ],
          ),
        ),
        VerticalDivider(width: 1),
        SizedBox(
          width: 64,
          child: ElementLibrary(mode: ElementLibraryMode.compact),
        ),
      ],
    );
  }

  void _openTreeSheet(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: _editor,
          child: DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        l10n.tree,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: PrimaryScrollController(
                        controller: scrollController,
                        child: const TreeView(),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _addPage(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.newPage),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.pageName,
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
              child: Text(l10n.create),
            ),
          ],
        );
      },
    );
    if (name != null && name.isNotEmpty) {
      _editor.addPage(name);
    }
  }

  Future<void> _exportZip(BuildContext context, ExportTarget target) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context, rootNavigator: true);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(l10n.exporting),
              ],
            ),
          ),
        ),
      ),
    );
    try {
      await _saveNow(showSnack: false);
      await ExportService().shareZip(widget.project, target: target);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportSuccess)));
    } catch (e) {
      navigator.pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportFailed(e.toString()))),
      );
    }
  }
}
