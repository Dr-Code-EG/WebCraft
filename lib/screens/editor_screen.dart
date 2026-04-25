import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/element_node.dart';
import '../models/project.dart';
import '../services/export_service.dart';
import '../state/editor_provider.dart';
import '../state/projects_provider.dart';
import '../widgets/editor/canvas_view.dart';
import '../widgets/editor/element_library.dart';
import '../widgets/editor/properties_panel.dart';
import '../widgets/editor/tree_view.dart';
import 'block_editor_screen.dart';
import 'preview_screen.dart';

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
              title: Text(widget.project.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              actions: [
                IconButton(
                  tooltip: l10n.pageLogic,
                  icon: const Icon(Icons.code_rounded),
                  onPressed: () => _editPageLogic(context),
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
                IconButton(
                  tooltip: l10n.exportZip,
                  icon: const Icon(Icons.ios_share_rounded),
                  onPressed: () => _exportZip(context),
                ),
              ],
            ),
            body: wide ? _wideLayout() : _phoneLayout(context, l10n),
            floatingActionButton:
                wide ? null : _buildPhoneFabRow(context, l10n),
          );
        },
      ),
    );
  }

  Widget _wideLayout() {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 240, child: ElementLibrary()),
        VerticalDivider(width: 1),
        SizedBox(width: 220, child: TreeView()),
        VerticalDivider(width: 1),
        Expanded(child: CanvasView()),
        VerticalDivider(width: 1),
        SizedBox(width: 320, child: PropertiesPanel()),
      ],
    );
  }

  Widget _phoneLayout(BuildContext context, AppLocalizations l10n) {
    return const Padding(
      padding: EdgeInsets.only(bottom: 80),
      child: CanvasView(),
    );
  }

  Widget _buildPhoneFabRow(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetFab(
            icon: Icons.widgets_outlined,
            label: l10n.elements,
            heroTag: 'fab-elements',
            onPressed: () => _openSheet(
              context,
              title: l10n.elements,
              child: const ElementLibrary(),
            ),
          ),
          const SizedBox(width: 8),
          _SheetFab(
            icon: Icons.account_tree_outlined,
            label: l10n.tree,
            heroTag: 'fab-tree',
            onPressed: () => _openSheet(
              context,
              title: l10n.tree,
              child: const TreeView(),
            ),
          ),
          const SizedBox(width: 8),
          _SheetFab(
            icon: Icons.tune_rounded,
            label: l10n.properties,
            heroTag: 'fab-props',
            onPressed: () => _openSheet(
              context,
              title: l10n.properties,
              child: const PropertiesPanel(),
            ),
          ),
        ],
      ),
    );
  }

  void _openSheet(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
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
                        title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    Expanded(
                      child: PrimaryScrollController(
                        controller: scrollController,
                        child: child,
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

  Future<void> _editPageLogic(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final page = _editor.activePage;
    final existing = page.events['onLoad'];
    final result = await BlockEditorScreen.open(
      context,
      title: l10n.blockEditorTitle(l10n.onLoad),
      initialXml: existing?.workspaceXml ?? '',
    );
    if (result != null) {
      _editor.setPageEvent(
        'onLoad',
        ElementEvent(
          workspaceXml: result.workspaceXml,
          jsBody: result.jsBody,
        ),
      );
    }
  }

  Future<void> _exportZip(BuildContext context) async {
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
      await ExportService().shareZip(widget.project);
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

class _SheetFab extends StatelessWidget {
  const _SheetFab({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.heroTag,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      heroTag: heroTag,
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label),
      elevation: 2,
    );
  }
}
