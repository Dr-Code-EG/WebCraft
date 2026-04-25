/// Reset / global stylesheet emitted alongside generated pages.
class CssGenerator {
  static String baseStylesheet() {
    return '''/* WebCraft generated stylesheet */
* { box-sizing: border-box; }

html, body {
  margin: 0;
  padding: 0;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto,
               "Helvetica Neue", Arial, sans-serif;
  color: #111827;
  background: #ffffff;
  line-height: 1.5;
}

img { max-width: 100%; display: block; }

button { font-family: inherit; }

a { color: inherit; }

h1, h2, h3, h4, h5, h6, p { margin: 0; }
''';
  }
}
