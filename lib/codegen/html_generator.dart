import '../models/element_node.dart';
import '../models/page_node.dart';
import '../models/project.dart';

/// Pure functions that turn a [Project] / [PageNode] tree into HTML.
class HtmlGenerator {
  /// Build a complete HTML document for [page].
  static String pageDocument(Project project, PageNode page,
      {bool includeStyleSheet = true,
      bool includeScript = true,
      String scriptHref = 'assets/js/main.js'}) {
    final body = element(page.root, indent: 2);
    final styleLink = includeStyleSheet
        ? '<link rel="stylesheet" href="assets/css/styles.css">'
        : '';
    final scriptTag =
        includeScript ? '<script defer src="$scriptHref"></script>' : '';
    final title = _escape(page.title.isNotEmpty ? page.title : project.name);

    return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$title</title>
  $styleLink
  $scriptTag
</head>
<body>
$body
</body>
</html>
''';
  }

  /// Render a single [node] (recursively) as HTML, preserving inline styles.
  static String element(ElementNode node, {int indent = 0}) {
    final pad = '  ' * indent;
    final styleAttr = _styleAttr(node.style);
    final classAttr = _attr('class', node.props['class']);
    final idAttr = _attr('id', node.props['id']);
    final wcId = ' data-wc-id="${node.id}"';

    switch (node.type) {
      case ElementType.heading:
        final level = node.props['level'] ?? 'h1';
        return '$pad<$level$idAttr$classAttr$wcId$styleAttr>${_escape(node.props['text'] ?? '')}</$level>';

      case ElementType.paragraph:
        return '$pad<p$idAttr$classAttr$wcId$styleAttr>${_escape(node.props['text'] ?? '')}</p>';

      case ElementType.text:
        return '$pad<span$idAttr$classAttr$wcId$styleAttr>${_escape(node.props['text'] ?? '')}</span>';

      case ElementType.button:
        final type = node.props['type'] ?? 'button';
        return '$pad<button type="$type"$idAttr$classAttr$wcId$styleAttr>${_escape(node.props['text'] ?? 'Button')}</button>';

      case ElementType.image:
        final src = _escape(node.props['src'] ?? '');
        final alt = _escape(node.props['alt'] ?? '');
        return '$pad<img src="$src" alt="$alt"$idAttr$classAttr$wcId$styleAttr>';

      case ElementType.input:
        final type = node.props['type'] ?? 'text';
        final placeholder = _attr('placeholder', node.props['placeholder']);
        final name = _attr('name', node.props['name']);
        return '$pad<input type="$type"$name$placeholder$idAttr$classAttr$wcId$styleAttr>';

      case ElementType.textarea:
        final placeholder = _attr('placeholder', node.props['placeholder']);
        final rows = _attr('rows', node.props['rows']);
        final name = _attr('name', node.props['name']);
        return '$pad<textarea$name$placeholder$rows$idAttr$classAttr$wcId$styleAttr></textarea>';

      case ElementType.link:
        final href = _attr('href', node.props['href']);
        final text = node.children.isEmpty
            ? _escape(node.props['text'] ?? 'link')
            : _renderChildren(node.children, indent + 1);
        if (node.children.isEmpty) {
          return '$pad<a$href$idAttr$classAttr$wcId$styleAttr>$text</a>';
        }
        return '$pad<a$href$idAttr$classAttr$wcId$styleAttr>\n$text\n$pad</a>';

      case ElementType.divider:
        return '$pad<hr$idAttr$classAttr$wcId$styleAttr>';

      case ElementType.spacer:
        return '$pad<div$idAttr$classAttr$wcId$styleAttr></div>';

      case ElementType.list:
        final ordered = (node.props['ordered'] ?? 'false') == 'true';
        final tag = ordered ? 'ol' : 'ul';
        final items = node.children
            .map((c) =>
                '${'  ' * (indent + 1)}<li>${element(c, indent: 0).trim()}</li>')
            .join('\n');
        return '$pad<$tag$idAttr$classAttr$wcId$styleAttr>\n$items\n$pad</$tag>';

      case ElementType.video:
        final src = _attr('src', node.props['src']);
        final controls =
            (node.props['controls'] ?? 'true') == 'true' ? ' controls' : '';
        return '$pad<video$src$controls$idAttr$classAttr$wcId$styleAttr></video>';

      case ElementType.form:
        final action = _attr('action', node.props['action']);
        final method = _attr('method', node.props['method']);
        final inner = _renderChildren(node.children, indent + 1);
        return '$pad<form$action$method$idAttr$classAttr$wcId$styleAttr>\n$inner\n$pad</form>';

      case ElementType.container:
      case ElementType.row:
      case ElementType.column:
      case ElementType.card:
        final inner = _renderChildren(node.children, indent + 1);
        if (inner.isEmpty) {
          return '$pad<div$idAttr$classAttr$wcId$styleAttr></div>';
        }
        return '$pad<div$idAttr$classAttr$wcId$styleAttr>\n$inner\n$pad</div>';
    }
  }

  static String _renderChildren(List<ElementNode> children, int indent) {
    return children.map((c) => element(c, indent: indent)).join('\n');
  }

  static String _styleAttr(Map<String, String> style) {
    if (style.isEmpty) return '';
    final body = style.entries
        .where((e) => e.value.trim().isNotEmpty)
        .map((e) => '${e.key}: ${e.value};')
        .join(' ');
    if (body.isEmpty) return '';
    return ' style="$body"';
  }

  static String _attr(String name, String? value) {
    if (value == null || value.trim().isEmpty) return '';
    return ' $name="${_escape(value)}"';
  }

  static String _escape(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;');
  }
}
