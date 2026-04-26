import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/blocks/catalog/block_registry.dart';
import 'package:webcraft/blocks/model/block_node.dart';
import 'package:webcraft/blocks/model/block_types.dart';
import 'package:webcraft/blocks/model/block_workspace.dart';
import 'package:webcraft/models/project.dart';

void main() {
  setUp(() => BlockRegistry.instance.seedDefaults());

  group('BlockType', () {
    test('parses ids and accepts only matching types', () {
      expect(BlockType.parse('number'), BlockType.number);
      expect(BlockType.parse(null), BlockType.any);
      expect(BlockType.parse('garbage'), BlockType.any);

      expect(BlockType.number.accepts(BlockType.number), isTrue);
      expect(BlockType.number.accepts(BlockType.text), isFalse);
      // any is bidirectional
      expect(BlockType.any.accepts(BlockType.text), isTrue);
      expect(BlockType.text.accepts(BlockType.any), isTrue);
    });
  });

  group('BlockShape notches', () {
    test('hat has only bottom notch', () {
      expect(BlockShape.hat.hasPrevNotch, isFalse);
      expect(BlockShape.hat.hasNextNotch, isTrue);
    });

    test('expression has neither', () {
      expect(BlockShape.expression.hasPrevNotch, isFalse);
      expect(BlockShape.expression.hasNextNotch, isFalse);
    });

    test('cap has only top notch', () {
      expect(BlockShape.cap.hasPrevNotch, isTrue);
      expect(BlockShape.cap.hasNextNotch, isFalse);
    });
  });

  group('BlockRegistry', () {
    test('seed contains the core demo blocks', () {
      final r = BlockRegistry.instance;
      for (final id in [
        'on_page_load',
        'on_click',
        'set_var',
        'get_var',
        'number_literal',
        'math_binop',
        'text_literal',
        'if_else',
        'compare',
        'dom_set_text',
        'dom_get_value',
      ]) {
        expect(r.lookup(id), isNotNull, reason: 'missing seed spec: $id');
      }
    });

    test('byCategory groups correctly', () {
      final logic = BlockRegistry.instance.byCategory(BlockCategory.logic);
      expect(logic.map((s) => s.id), containsAll(['if_else', 'compare']));
    });
  });

  group('BlockNode roundtrip', () {
    test('field-only node survives toJson/fromJson', () {
      final n = BlockNode(
        specId: 'number_literal',
        fieldValues: {'value': '42'},
      );
      final j = jsonDecode(jsonEncode(n.toJson())) as Map<String, dynamic>;
      final back = BlockNode.fromJson(j);
      expect(back.specId, 'number_literal');
      expect(back.fieldValues['value'], '42');
    });

    test('nested slots + chained next survive roundtrip', () {
      final inner = BlockNode(
        specId: 'number_literal',
        fieldValues: {'value': '7'},
      );
      final outer = BlockNode(
        specId: 'set_var',
        fieldValues: {'name': 'x'},
        slotChildren: {'value': inner},
      );
      final tail = BlockNode(specId: 'on_page_load');
      // (artificial chain just to verify serialization)
      outer.next = tail;

      final j = jsonDecode(jsonEncode(outer.toJson())) as Map<String, dynamic>;
      final back = BlockNode.fromJson(j);
      expect(back.specId, 'set_var');
      expect(back.fieldValues['name'], 'x');
      expect(back.slotChildren['value']?.specId, 'number_literal');
      expect(back.slotChildren['value']?.fieldValues['value'], '7');
      expect(back.next?.specId, 'on_page_load');
    });

    test('mouth stacks survive roundtrip', () {
      final body = BlockNode(specId: 'dom_set_text');
      final ifBlock = BlockNode(
        specId: 'if_else',
        mouthStacks: {
          'then': [body],
          'else': [],
        },
      );
      final j =
          jsonDecode(jsonEncode(ifBlock.toJson())) as Map<String, dynamic>;
      final back = BlockNode.fromJson(j);
      expect(back.mouthStacks['then']?.first.specId, 'dom_set_text');
      expect(back.mouthStacks['else'], isNotNull);
      expect(back.mouthStacks['else']!.isEmpty, isTrue);
    });

    test('duplicate produces fresh ids', () {
      final n = BlockNode(specId: 'number_literal');
      final clone = n.duplicate();
      expect(clone.id, isNot(n.id));
      expect(clone.specId, n.specId);
    });

    test('walk visits all descendants', () {
      final inner = BlockNode(specId: 'number_literal');
      final outer = BlockNode(
        specId: 'set_var',
        slotChildren: {'value': inner},
      );
      final ids = outer.walk().map((n) => n.id).toList();
      expect(ids.length, 2);
      expect(ids.contains(inner.id), isTrue);
      expect(ids.contains(outer.id), isTrue);
    });
  });

  group('BlockWorkspace + Project integration', () {
    test('workspace ids are stable and namespaced', () {
      expect(WorkspaceIds.forPage('p1'), 'page:p1:onLoad');
      expect(WorkspaceIds.forElement('e1', 'onClick'), 'el:e1:onClick');
    });

    test('empty workspaces are pruned in Project.toJson', () {
      final p = Project(name: 'demo');
      p.workspaces[WorkspaceIds.forPage(p.activePage.id)] = BlockWorkspace(
        id: WorkspaceIds.forPage(p.activePage.id),
      );
      final j = p.toJson();
      expect((j['workspaces'] as Map).isEmpty, isTrue);
    });

    test('non-empty workspaces survive Project roundtrip', () {
      final p = Project(name: 'demo');
      final wsId = WorkspaceIds.forPage(p.activePage.id);
      p.workspaces[wsId] = BlockWorkspace(
        id: wsId,
        roots: [BlockNode(specId: 'on_page_load')],
        variables: [VariableDecl(name: 'count', type: BlockType.number)],
      );

      final json = jsonDecode(jsonEncode(p.toJson())) as Map<String, dynamic>;
      final back = Project.fromJson(json);
      expect(back.workspaces, contains(wsId));
      expect(back.workspaces[wsId]!.roots.first.specId, 'on_page_load');
      expect(back.workspaces[wsId]!.variables.first.name, 'count');
      expect(back.workspaces[wsId]!.variables.first.type, BlockType.number);
    });
  });
}
