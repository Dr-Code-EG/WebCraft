import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/codegen/css_generator.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';

Project _seed() => Project(
      name: 'P',
      pages: [
        PageNode(
          name: 'Home',
          fileName: 'index.html',
          title: 'Home',
          root: ElementNode.defaults(ElementType.container),
        ),
      ],
    );

void main() {
  test('themeBlock emits a :root rule for the given map', () {
    final css = CssGenerator.themeBlock({
      '--primary': '#ff0066',
      '--bg': '#000',
    });
    expect(css, contains(':root'));
    expect(css, contains('--primary: #ff0066;'));
    expect(css, contains('--bg: #000;'));
  });

  test('themeBlock returns empty string when no vars', () {
    expect(CssGenerator.themeBlock(const {}), isEmpty);
  });

  test('stylesheetFor includes theme + base + custom CSS in order', () {
    final p = _seed();
    p.themeVars['--accent'] = '#7c3aed';
    p.customCss = '.special { color: red; }';
    final css = CssGenerator.stylesheetFor(p);

    final themeIdx = css.indexOf('--accent: #7c3aed;');
    final baseIdx = css.indexOf('box-sizing: border-box');
    final customIdx = css.indexOf('.special { color: red; }');
    expect(themeIdx, greaterThanOrEqualTo(0));
    expect(baseIdx, greaterThan(themeIdx));
    expect(customIdx, greaterThan(baseIdx));
  });
}
