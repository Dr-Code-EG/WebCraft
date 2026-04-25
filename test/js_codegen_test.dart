import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/codegen/js_generator.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/project.dart';

void main() {
  group('JsGenerator', () {
    test('emits empty wrapper when no events configured', () {
      final p = Project(name: 'demo');
      final js = JsGenerator.pageScript(p.pages.first);
      expect(js, contains('DOMContentLoaded'));
      expect(js, isNot(contains('addEventListener("click"')));
    });

    test('binds onClick handler using data-wc-id when no explicit id is set',
        () {
      final p = Project(name: 'demo');
      final btn = ElementNode.defaults(ElementType.button);
      btn.events['onClick'] =
          ElementEvent(workspaceXml: '<xml/>', jsBody: 'alert("hi");');
      p.pages.first.root.children.add(btn);

      final js = JsGenerator.pageScript(p.pages.first);
      expect(js, contains('addEventListener("click"'));
      expect(js, contains("data-wc-id='${btn.id}'"));
      expect(js, contains('alert("hi");'));
    });

    test('uses explicit id when set', () {
      final p = Project(name: 'demo');
      final btn = ElementNode.defaults(ElementType.button);
      btn.props['id'] = 'submit-btn';
      btn.events['onClick'] = ElementEvent(workspaceXml: '', jsBody: 'foo();');
      p.pages.first.root.children.add(btn);

      final js = JsGenerator.pageScript(p.pages.first);
      expect(js, contains('document.getElementById("submit-btn")'));
    });

    test('emits page onLoad block at top of ready handler', () {
      final p = Project(name: 'demo');
      p.pages.first.events['onLoad'] =
          ElementEvent(workspaceXml: '', jsBody: 'console.log("loaded");');
      final js = JsGenerator.pageScript(p.pages.first);
      expect(js, contains('console.log("loaded");'));
      expect(js, contains('Page onLoad'));
    });

    test('roundtrip: events serialize through Project JSON', () {
      final p = Project(name: 'demo');
      final btn = ElementNode.defaults(ElementType.button);
      btn.events['onClick'] =
          ElementEvent(workspaceXml: '<xml/>', jsBody: 'alert(1);');
      p.pages.first.root.children.add(btn);

      final restored = Project.fromJson(p.toJson());
      final restoredBtn = restored.pages.first.root.children.first;
      expect(restoredBtn.events.containsKey('onClick'), isTrue);
      expect(restoredBtn.events['onClick']!.jsBody, 'alert(1);');
      expect(restoredBtn.events['onClick']!.workspaceXml, '<xml/>');
    });
  });
}
