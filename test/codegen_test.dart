import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/codegen/html_generator.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';

void main() {
  group('HtmlGenerator', () {
    test('renders heading with text and level', () {
      final node = ElementNode.defaults(ElementType.heading);
      node.props['text'] = 'Hello';
      node.props['level'] = 'h2';
      final out = HtmlGenerator.element(node);
      expect(out, contains('<h2'));
      expect(out, contains('Hello'));
    });

    test('renders nested container with children', () {
      final root = ElementNode.defaults(ElementType.container);
      final btn = ElementNode.defaults(ElementType.button);
      btn.props['text'] = 'Click';
      root.children.add(btn);

      final out = HtmlGenerator.element(root);
      expect(out, contains('<div'));
      expect(out, contains('<button'));
      expect(out, contains('Click'));
    });

    test('escapes HTML in text content', () {
      final node = ElementNode.defaults(ElementType.paragraph);
      node.props['text'] = '<script>alert(1)</script>';
      final out = HtmlGenerator.element(node);
      expect(out, contains('&lt;script&gt;'));
      expect(out.contains('<script>alert'), isFalse);
    });

    test('emits inline styles', () {
      final node = ElementNode.defaults(ElementType.text);
      node.style['color'] = '#ff0000';
      node.style['font-size'] = '20px';
      final out = HtmlGenerator.element(node);
      expect(out, contains('color: #ff0000;'));
      expect(out, contains('font-size: 20px;'));
    });

    test('emits data-wc-id on every element for handler binding', () {
      final node = ElementNode.defaults(ElementType.button);
      node.props['text'] = 'Go';
      final out = HtmlGenerator.element(node);
      expect(out, contains('data-wc-id="${node.id}"'));
    });

    test('omits the main script tag when includeMainScript is false', () {
      final project = Project(name: 'Test');
      final html = HtmlGenerator.pageDocument(project, project.pages.first,
          includeMainScript: false);
      expect(html, isNot(contains('assets/js/main.js')));
    });

    test('renders a full page document with stylesheet link', () {
      final project = Project(name: 'Test');
      final page = project.pages.first;
      page.title = 'My Title';
      final btn = ElementNode.defaults(ElementType.button);
      btn.props['text'] = 'Submit';
      page.root.children.add(btn);

      final html = HtmlGenerator.pageDocument(project, page);
      expect(html, startsWith('<!DOCTYPE html>'));
      expect(html, contains('<title>My Title</title>'));
      expect(html, contains('assets/css/styles.css'));
      expect(html, contains('Submit'));
    });

    test('roundtrip: project JSON serialization', () {
      final project = Project(name: 'Demo');
      final page = project.pages.first;
      final txt = ElementNode.defaults(ElementType.heading);
      txt.props['text'] = 'Hi';
      page.root.children.add(txt);

      final json = project.toJson();
      final restored = Project.fromJson(json);
      expect(restored.name, 'Demo');
      expect(restored.pages.first.root.children.length, 1);
      expect(
        restored.pages.first.root.children.first.props['text'],
        'Hi',
      );
    });
  });

  group('PageNode', () {
    test('uses provided fileName and title', () {
      final p =
          PageNode(name: 'About', fileName: 'about.html', title: 'About us');
      expect(p.fileName, 'about.html');
      expect(p.title, 'About us');
    });
  });
}
