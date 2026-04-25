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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saved')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return ChangeNotifierProvider.value(
      value: _editor,
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
            title: Text(widget.project.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                tooltip: l10n.pageLogic,
                icon: const Icon(Icons.code),
                onPressed: () => _editPageLogic(context),
              ),
              IconButton(
                tooltip: l10n.preview,
                icon: const Icon(Icons.visibility_outlined),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => PreviewScreen(project: widget.project),
                  ));
                },
              ),
              IconButton(
                tooltip: l10n.exportZip,
                icon: const Icon(Icons.ios_share),
                onPressed: () => _exportZip(context),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(
                    icon: const Icon(Icons.widgets_outlined),
                    text: l10n.elements),
                Tab(
                    icon: const Icon(Icons.account_tree_outlined),
                    text: l10n.tree),
                Tab(icon: const Icon(Icons.tune), text: l10n.properties),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 900;
        if (wide) {
          return const Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(width: 240, child: ElementLibrary()),
              VerticalDivider(width: 1),
              Expanded(child: CanvasView()),
              VerticalDivider(width: 1),
              SizedBox(width: 320, child: PropertiesPanel()),
            ],
          );
        }
        return const Column(
          children: [
            Expanded(
              child: TabBarView(
                children: [
                  ElementLibrary(),
                  TreeView(),
                  PropertiesPanel(),
                ],
              ),
            ),
            Divider(height: 1),
            SizedBox(
              height: 280,
              child: CanvasView(),
            ),
          ],
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                    width: 24, height: 24, child: CircularProgressIndicator()),
                const SizedBox(width: 16),
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
          SnackBar(content: Text(l10n.exportFailed(e.toString()))));
    }
  }
}
