import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';
import 'package:webcraft/state/editor_provider.dart';

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
  test('copy + paste duplicates the selected element with new ids', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.heading);
    final original = ed.activePage.root.children.single;
    ed.select(original.id);

    expect(ed.copySelection(), isTrue);
    expect(ed.hasClipboard, isTrue);

    final newId = ed.pasteFromClipboard();
    expect(newId, isNotNull);
    expect(newId, isNot(equals(original.id)));
    expect(ed.activePage.root.children, hasLength(2));
    expect(ed.activePage.root.children.last.type, ElementType.heading);
  });

  test('cut removes the selection and primes the clipboard', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.button);
    final id = ed.activePage.root.children.single.id;
    ed.select(id);

    expect(ed.cutSelection(), isTrue);
    expect(ed.activePage.root.children, isEmpty);
    expect(ed.hasClipboard, isTrue);

    ed.pasteFromClipboard();
    expect(ed.activePage.root.children, hasLength(1));
    expect(ed.activePage.root.children.single.type, ElementType.button);
  });

  test('saveSelectionAsComponent stores a deep clone with fresh ids', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.card);
    final card = ed.activePage.root.children.single;
    ed.select(card.id);
    ed.addElementInside(ElementType.heading, card.id);
    ed.select(card.id);

    final comp = ed.saveSelectionAsComponent('Hero');
    expect(comp, isNotNull);
    expect(ed.project.components, hasLength(1));
    expect(comp!.root.id, isNot(equals(card.id)));
    expect(comp.root.children, hasLength(1));
    expect(comp.root.children.single.type, ElementType.heading);
  });

  test('insertComponent appends a fresh clone into the drop parent', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.heading);
    ed.select(ed.activePage.root.children.single.id);
    final comp = ed.saveSelectionAsComponent('Title')!;

    final newId = ed.insertComponent(comp);
    expect(newId, isNotNull);
    expect(ed.activePage.root.children, hasLength(2));
  });

  test('theme vars and custom CSS round-trip through Project JSON', () {
    final p = _seed();
    p.themeVars['--primary'] = '#ff0066';
    p.customCss = 'body { background: red; }';
    final json = p.toJson();
    final restored = Project.fromJson(json);
    expect(restored.themeVars['--primary'], '#ff0066');
    expect(restored.customCss, 'body { background: red; }');
  });
}
