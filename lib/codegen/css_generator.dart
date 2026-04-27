import '../models/project.dart';

/// Reset / global stylesheet emitted alongside generated pages.
class CssGenerator {
  /// The static reset that every project ships. Kept as a separate getter so
  /// tests can verify it independently of theme/customCss output.
  static String baseStylesheet() {
    return '''/* WebCraft generated stylesheet */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  color: var(--text, #111827);
  background: var(--bg, #ffffff);
  line-height: 1.5;
  font-size: var(--font-base, 16px);
}

img { max-width: 100%; display: block; }

button { font-family: inherit; }

a { color: inherit; }

h1, h2, h3, h4, h5, h6, p { margin: 0; }
''';
  }

  /// Emit a `:root { --name: value; ... }` block for the project's editable
  /// theme variables. Returns the empty string when no variables are set.
  static String themeBlock(Map<String, String> themeVars) {
    if (themeVars.isEmpty) return '';
    final entries = themeVars.entries
        .where((e) => e.key.isNotEmpty)
        .map((e) => '  ${e.key}: ${e.value};')
        .join('\n');
    if (entries.isEmpty) return '';
    return ':root {\n$entries\n}\n';
  }

  /// Build the complete stylesheet served as `assets/css/styles.css`:
  /// theme variables → reset → user's custom CSS.
  static String stylesheetFor(Project project) {
    final buf = StringBuffer();
    final theme = themeBlock(project.themeVars);
    if (theme.isNotEmpty) {
      buf.writeln(theme);
    }
    buf.writeln(baseStylesheet());
    if (project.customCss.trim().isNotEmpty) {
      buf.writeln('/* Custom CSS */');
      buf.writeln(project.customCss.trim());
    }
    return buf.toString();
  }
}
