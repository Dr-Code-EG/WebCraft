import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../codegen/blocks_js_generator.dart';
import '../codegen/css_generator.dart';
import '../codegen/html_generator.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/project.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.project});

  final Project project;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final WebViewController _controller;
  String _activePageId = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _activePageId = widget.project.activePageId;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => setState(() => _loading = false),
      ));
    _loadActivePage();
  }

  void _loadActivePage() {
    final page = widget.project.pages.firstWhere((p) => p.id == _activePageId,
        orElse: () => widget.project.pages.first);
    final body = HtmlGenerator.pageDocument(widget.project, page,
        includeStyleSheet: false, includeMainScript: false);
    final css = CssGenerator.baseStylesheet();
    final js = BlocksJsGenerator.generateProject(widget.project);
    final scriptTag = js.isEmpty ? '' : '<script>$js</script>';
    // Inject the generated stylesheet + script inline so the WebView preview
    // is self-contained (no external file lookups).
    final injected = body
        .replaceFirst('</head>', '<style>$css</style></head>')
        .replaceFirst('</body>', '$scriptTag</body>');
    setState(() => _loading = true);
    _controller.loadHtmlString(injected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.preview),
        actions: [
          IconButton(
            tooltip: 'Reload',
            icon: const Icon(Icons.refresh),
            onPressed: _loadActivePage,
          ),
        ],
        bottom: widget.project.pages.length > 1
            ? PreferredSize(
                preferredSize: const Size.fromHeight(48),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      for (final p in widget.project.pages)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: ChoiceChip(
                            selected: p.id == _activePageId,
                            label: Text(p.name),
                            onSelected: (_) {
                              setState(() => _activePageId = p.id);
                              _loadActivePage();
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              )
            : null,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x99FFFFFF),
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
        ],
      ),
    );
  }
}
