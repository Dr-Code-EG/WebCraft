import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Result returned to callers when the user saves the block workspace.
class BlockEditorResult {
  BlockEditorResult({required this.workspaceXml, required this.jsBody});

  final String workspaceXml;
  final String jsBody;
}

/// Hosts the bundled Blockly editor in a WebView and round-trips workspace XML
/// + generated JavaScript with the Flutter side via a JavaScript channel.
class BlockEditorScreen extends StatefulWidget {
  const BlockEditorScreen({
    super.key,
    required this.title,
    required this.initialXml,
  });

  final String title;
  final String initialXml;

  @override
  State<BlockEditorScreen> createState() => _BlockEditorScreenState();

  static Future<BlockEditorResult?> open(
    BuildContext context, {
    required String title,
    required String initialXml,
  }) {
    return Navigator.of(context).push<BlockEditorResult>(
      MaterialPageRoute(
        builder: (_) => BlockEditorScreen(title: title, initialXml: initialXml),
        fullscreenDialog: true,
      ),
    );
  }
}

class _BlockEditorScreenState extends State<BlockEditorScreen> {
  late final WebViewController _controller;
  bool _ready = false;
  String _xml = '';
  String _js = '';

  @override
  void initState() {
    super.initState();
    _xml = widget.initialXml;
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'WebCraftHost',
        onMessageReceived: _handleMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) => _onPageReady(),
      ));
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final html = await rootBundle.loadString('assets/blockly/index.html');
    final blockly =
        await rootBundle.loadString('assets/blockly/blockly_compressed.js');
    final blocks =
        await rootBundle.loadString('assets/blockly/blocks_compressed.js');
    final js =
        await rootBundle.loadString('assets/blockly/javascript_compressed.js');
    final localeCode =
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    final msgPath = localeCode == 'ar'
        ? 'assets/blockly/msg_ar.js'
        : 'assets/blockly/msg_en.js';
    final msg = await rootBundle.loadString(msgPath);
    final custom =
        await rootBundle.loadString('assets/blockly/custom_blocks.js');

    final inlined = html
        .replaceFirst('<script src="blockly_compressed.js"></script>',
            '<script>$blockly</script>')
        .replaceFirst('<script src="blocks_compressed.js"></script>',
            '<script>$blocks</script>')
        .replaceFirst('<script src="javascript_compressed.js"></script>',
            '<script>$js</script>')
        .replaceFirst(
            '<script src="msg_en.js"></script>', '<script>$msg</script>')
        .replaceFirst('<script src="custom_blocks.js"></script>',
            '<script>$custom</script>');

    await _controller.loadHtmlString(inlined);
  }

  Future<void> _onPageReady() async {
    if (_ready) return;
    _ready = true;
    final escaped = jsonEncode(widget.initialXml);
    await _controller.runJavaScript('loadXml($escaped);');
  }

  void _handleMessage(JavaScriptMessage msg) {
    try {
      final decoded = jsonDecode(msg.message) as Map<String, dynamic>;
      final channel = decoded['channel'] as String?;
      final payload = decoded['payload'] as Map<String, dynamic>?;
      if (channel == 'change' && payload != null) {
        _xml = (payload['xml'] as String?) ?? _xml;
        _js = (payload['code'] as String?) ?? _js;
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    // Pull the very latest values from Blockly.
    final xml = await _controller
        .runJavaScriptReturningResult('getXml()')
        .then(_decodeJsString);
    final js = await _controller
        .runJavaScriptReturningResult('getCode()')
        .then(_decodeJsString);
    if (!mounted) return;
    Navigator.of(context).pop(BlockEditorResult(
      workspaceXml: xml.isNotEmpty ? xml : _xml,
      jsBody: js.isNotEmpty ? js : _js,
    ));
  }

  String _decodeJsString(Object? raw) {
    if (raw == null) return '';
    var s = raw.toString();
    if (s.startsWith('"') && s.endsWith('"')) {
      try {
        return jsonDecode(s) as String;
      } catch (_) {
        return s.substring(1, s.length - 1);
      }
    }
    return s;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
          actions: [
            TextButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, color: Colors.white),
              label:
                  Text(l10n.save, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
