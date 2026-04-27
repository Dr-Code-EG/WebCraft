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
  test('undo restores state before last mutation', () {
    final ed = EditorProvider(_seed());
    expect(ed.canUndo, isFalse);

    ed.addElement(ElementType.heading);
    expect(ed.activePage.root.children, hasLength(1));
    expect(ed.canUndo, isTrue);

    ed.undo();
    expect(ed.activePage.root.children, isEmpty);
    expect(ed.canRedo, isTrue);

    ed.redo();
    expect(ed.activePage.root.children, hasLength(1));
  });

  test('reorderElement moves a node above another sibling', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.heading); // A
    ed.addElement(ElementType.paragraph); // B
    final ids = ed.activePage.root.children.map((c) => c.id).toList();
    expect(ids, hasLength(2));

    ed.reorderElement(ids[1], ids[0], above: true);
    final reordered =
        ed.activePage.root.children.map((c) => c.id).toList();
    expect(reordered, [ids[1], ids[0]]);
  });

  test('replaceFromJson swaps state in place and is undoable', () {
    final ed = EditorProvider(_seed());
    ed.addElement(ElementType.heading);
    final after = _seed().toJson();
    ed.replaceFromJson(after);
    expect(ed.activePage.root.children, isEmpty);
    ed.undo();
    expect(ed.activePage.root.children, hasLength(1));
  });
}
