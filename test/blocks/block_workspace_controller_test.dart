import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/blocks/catalog/block_registry.dart';
import 'package:webcraft/blocks/model/block_node.dart';
import 'package:webcraft/blocks/model/block_types.dart';
import 'package:webcraft/blocks/model/block_workspace.dart';
import 'package:webcraft/blocks/state/block_workspace_controller.dart';

void main() {
  setUpAll(() => BlockRegistry.instance.seedDefaults());

  group('BlockWorkspaceController — drag/snap', () {
    test('addRootAt and select', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final node = BlockNode(specId: 'on_page_load');
      c.addRootAt(node, 10, 20);
      expect(c.workspace.roots.length, 1);
      expect(c.workspace.roots.first.x, 10);
      c.select(node.id);
      expect(c.selectedId, node.id);
    });

    test('insertAsNext snaps a Statement under a Hat', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final hat = BlockNode(specId: 'on_page_load');
      c.addRootAt(hat, 0, 0);

      final stmt = BlockNode(specId: 'set_var');
      final ok = c.insertAsNext(hat.id, stmt);
      expect(ok, true);
      expect(hat.next, isNotNull);
      expect(hat.next!.specId, 'set_var');
    });

    test('insertAsNext rejects an Expression block', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final hat = BlockNode(specId: 'on_page_load');
      c.addRootAt(hat, 0, 0);
      final expr = BlockNode(specId: 'math_binop');
      final ok = c.insertAsNext(hat.id, expr);
      expect(ok, false);
    });

    test('insertIntoSlot accepts compatible expression', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final ifBlock = BlockNode(specId: 'if_else');
      c.addRootAt(ifBlock, 0, 0);
      final eq = BlockNode(specId: 'compare');
      final ok = c.insertIntoSlot(ifBlock.id, 'cond', eq);
      expect(ok, true);
      expect(ifBlock.slotChildren['cond']?.specId, 'compare');
    });

    test('appendToMouth places the block in the mouth stack', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final ifBlock = BlockNode(specId: 'if_else');
      c.addRootAt(ifBlock, 0, 0);
      final stmt = BlockNode(specId: 'set_var');
      final ok = c.appendToMouth(ifBlock.id, 'then', stmt);
      expect(ok, true);
      expect(ifBlock.mouthStacks['then']?.first.specId, 'set_var');
    });

    test('cycle prevention — cannot snap parent under its own descendant', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final hat = BlockNode(specId: 'on_page_load');
      c.addRootAt(hat, 0, 0);
      final stmt = BlockNode(specId: 'set_var');
      c.insertAsNext(hat.id, stmt);
      // hat -> stmt. Now try to snap hat under stmt.
      final ok = c.insertAsNext(stmt.id, hat);
      expect(ok, false);
    });

    test('moveToRoot detaches a child and promotes it to a root', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final hat = BlockNode(specId: 'on_page_load');
      c.addRootAt(hat, 0, 0);
      final stmt = BlockNode(specId: 'set_var');
      c.insertAsNext(hat.id, stmt);
      c.moveToRoot(stmt.id, 100, 200);
      expect(c.workspace.roots.length, 2);
      expect(hat.next, isNull);
      expect(c.workspace.roots.last.id, stmt.id);
      expect(c.workspace.roots.last.x, 100);
    });

    test('moveToRoot preserves the dragged node\'s next chain', () {
      // A → B → C ;  drag B to canvas → expect A alone + B→C as new root.
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final a = BlockNode(specId: 'on_page_load');
      c.addRootAt(a, 0, 0);
      final b = BlockNode(specId: 'set_var');
      c.insertAsNext(a.id, b);
      final ccc = BlockNode(specId: 'set_var');
      c.insertAsNext(b.id, ccc);
      // sanity
      expect(a.next?.id, b.id);
      expect(b.next?.id, ccc.id);

      c.moveToRoot(b.id, 50, 60);
      expect(a.next, isNull, reason: 'A should be detached from B');
      expect(b.next?.id, ccc.id, reason: 'B should still own C');
      expect(c.workspace.roots.length, 2);
    });

    test('delete removes the entire subtree including the next chain', () {
      // A → B → C ; delete B → only A remains.
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final a = BlockNode(specId: 'on_page_load');
      c.addRootAt(a, 0, 0);
      final b = BlockNode(specId: 'set_var');
      c.insertAsNext(a.id, b);
      final ccc = BlockNode(specId: 'set_var');
      c.insertAsNext(b.id, ccc);

      c.delete(b.id);
      expect(c.workspace.roots.length, 1);
      expect(a.next, isNull);
      // C should not have re-appeared as a root.
      expect(c.findById(ccc.id), isNull);
    });

    test('delete removes the subtree', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final hat = BlockNode(specId: 'on_page_load');
      c.addRootAt(hat, 0, 0);
      c.delete(hat.id);
      expect(c.workspace.roots, isEmpty);
    });

    test('setField updates the field map', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      final n = BlockNode(specId: 'set_var');
      c.addRootAt(n, 0, 0);
      c.setField(n.id, 'name', 'counter');
      expect(n.fieldValues['name'], 'counter');
    });
  });

  group('BlockWorkspaceController — variables', () {
    test('addVariable / removeVariable / renameVariable', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      expect(c.addVariable('counter'), true);
      expect(c.workspace.variables.length, 1);
      expect(c.addVariable('counter'), false); // duplicate
      expect(c.renameVariable('counter', 'count'), true);
      expect(c.workspace.variables.first.name, 'count');
      c.removeVariable('count');
      expect(c.workspace.variables, isEmpty);
    });

    test('renameVariable updates only variable-kind field values', () {
      // dom_set_style has a `prop` text field with default 'color'. A
      // variable named 'color' renamed to 'hue' must NOT touch the text field.
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      c.addVariable('color');
      final styleNode = BlockNode(specId: 'dom_set_style');
      c.addRootAt(styleNode, 0, 0);
      // Manually set the prop text field to 'color' — same string as the var.
      c.setField(styleNode.id, 'prop', 'color');
      // And a real variable reference via set_var.
      final setNode = BlockNode(specId: 'set_var');
      c.addRootAt(setNode, 0, 0);
      c.setField(setNode.id, 'name', 'color');

      expect(c.renameVariable('color', 'hue'), true);

      // The set_var.name (BlockFieldKind.variable) should be renamed.
      expect(setNode.fieldValues['name'], 'hue');
      // The dom_set_style.prop (BlockFieldKind.text) must be untouched.
      expect(styleNode.fieldValues['prop'], 'color');
    });

    test('addVariable rejects empty name', () {
      final c = BlockWorkspaceController(BlockWorkspace(id: 't'));
      expect(c.addVariable(''), false);
      expect(c.addVariable('   '), false);
    });
  });

  group('BlockWorkspaceController — type system', () {
    test('BlockType.accepts is bidirectional with `any`', () {
      expect(BlockType.any.accepts(BlockType.number), true);
      expect(BlockType.number.accepts(BlockType.any), true);
      expect(BlockType.number.accepts(BlockType.text), false);
    });
  });
}
