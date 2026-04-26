import 'package:flutter/material.dart';

import '../catalog/block_registry.dart';
import '../model/block_node.dart';
import 'block_widget.dart';

/// Debug-only sandbox showing every spec in the seed catalog rendered as a
/// real block, plus a small composite stack to demo nesting / mouths /
/// expression slotting. This is the Phase B0 "proof of life" — full
/// interaction lands in B1.
class BlocksPreviewScreen extends StatelessWidget {
  const BlocksPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final all = BlockRegistry.instance.all.toList();
    final composite = _compositeDemo();

    return Scaffold(
      appBar: AppBar(title: const Text('Blocks Preview · Phase B0')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Composite stack'),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: BlockWidget(node: composite),
            ),
            const SizedBox(height: 24),
            const _SectionTitle('All seed specs'),
            for (final spec in all) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 4),
                child: Text(
                  '${spec.id}  ·  ${spec.shape.id}  ·  '
                  '${spec.category.id}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
              BlockWidget(node: BlockNode(specId: spec.id)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

BlockNode _compositeDemo() {
  // When page loaded → set count to (1 + 2) → if (count == 3) then set text "ok"
  final hat = BlockNode(specId: 'on_page_load');

  final num1 = BlockNode(specId: 'number_literal', fieldValues: {'value': '1'});
  final num2 = BlockNode(specId: 'number_literal', fieldValues: {'value': '2'});
  final add = BlockNode(
    specId: 'math_binop',
    fieldValues: {'op': '+'},
    slotChildren: {'a': num1, 'b': num2},
  );
  final setVar = BlockNode(
    specId: 'set_var',
    fieldValues: {'name': 'count'},
    slotChildren: {'value': add},
  );

  final getVar = BlockNode(specId: 'get_var', fieldValues: {'name': 'count'});
  final num3 = BlockNode(specId: 'number_literal', fieldValues: {'value': '3'});
  final cmp = BlockNode(
    specId: 'compare',
    fieldValues: {'op': '=='},
    slotChildren: {'a': getVar, 'b': num3},
  );
  final txt = BlockNode(specId: 'text_literal', fieldValues: {'value': 'ok'});
  final setText = BlockNode(
    specId: 'dom_set_text',
    fieldValues: {'target': 'self'},
    slotChildren: {'value': txt},
  );
  final ifBlock = BlockNode(
    specId: 'if_else',
    slotChildren: {'cond': cmp},
    mouthStacks: {
      'then': [setText],
      'else': [],
    },
  );

  // Chain: hat → setVar → if
  hat.next = setVar;
  setVar.next = ifBlock;

  return hat;
}
