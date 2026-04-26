import 'package:flutter/material.dart';

import '../catalog/block_registry.dart';
import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_types.dart';
import 'block_drag_payload.dart';
import 'block_widget.dart';

/// Categorized vertical list of every registered [BlockSpec], grouped under
/// expandable category headers. Each entry is a [Draggable] (and a tap-to-add
/// fallback). When the host needs to show a thumbnail, it pulls a synthetic
/// [BlockNode] off the spec.
class BlocksToolbox extends StatefulWidget {
  const BlocksToolbox({
    super.key,
    required this.onTapBlock,
    this.searchHint = 'Search blocks',
  });

  /// Tap-to-add fallback for environments where dragging is awkward.
  final void Function(BlockSpec spec) onTapBlock;
  final String searchHint;

  @override
  State<BlocksToolbox> createState() => _BlocksToolboxState();
}

class _BlocksToolboxState extends State<BlocksToolbox> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final all = BlockRegistry.instance.all;
    final q = _query.text.trim().toLowerCase();

    // Group by category, optionally filtered.
    final grouped = <BlockCategory, List<BlockSpec>>{};
    for (final s in all) {
      if (q.isNotEmpty &&
          !s.id.toLowerCase().contains(q) &&
          !s.template.toLowerCase().contains(q)) {
        continue;
      }
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return Container(
      color: cs.surfaceContainerLowest,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: TextField(
              controller: _query,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search, size: 18),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 12),
              children: [
                for (final cat in BlockCategory.values)
                  if (grouped[cat] != null)
                    _CategoryGroup(
                      category: cat,
                      specs: grouped[cat]!,
                      onTap: widget.onTapBlock,
                    ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.specs,
    required this.onTap,
  });

  final BlockCategory category;
  final List<BlockSpec> specs;
  final void Function(BlockSpec spec) onTap;

  @override
  Widget build(BuildContext context) {
    final color = kCategoryColors[category]!;
    return Theme(
      data: Theme.of(context).copyWith(
        dividerColor: Colors.transparent,
        splashColor: color.withOpacity(0.10),
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(horizontal: 12),
        childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        leading: Container(
          width: 6,
          height: 22,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        title: Text(
          category.id.toUpperCase(),
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.7,
          ),
        ),
        children: [
          for (final s in specs) _ToolboxRow(spec: s, onTap: () => onTap(s)),
        ],
      ),
    );
  }
}

class _ToolboxRow extends StatelessWidget {
  const _ToolboxRow({required this.spec, required this.onTap});

  final BlockSpec spec;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // The visual is the actual block painted at idle scale. Dragging from the
    // toolbox carries a [BlockSpec]; the workspace drop site instantiates it.
    final preview = _ToolboxBlockPreview(spec: spec);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Draggable<BlockDragPayload>(
              data: BlockDragPayload.fromToolbox(spec),
              dragAnchorStrategy: childDragAnchorStrategy,
              feedback: Material(
                type: MaterialType.transparency,
                child: Opacity(opacity: 0.92, child: preview),
              ),
              childWhenDragging: Opacity(opacity: 0.4, child: preview),
              child: preview,
            ),
          ),
        ),
      ),
    );
  }
}

/// Renders a single block from a [BlockSpec] using a synthetic [BlockNode]
/// (default field values, no children). Used for toolbox tiles and drag
/// feedback.
class _ToolboxBlockPreview extends StatelessWidget {
  const _ToolboxBlockPreview({required this.spec});
  final BlockSpec spec;

  @override
  Widget build(BuildContext context) {
    final node = BlockNode(specId: spec.id);
    for (final f in spec.fields) {
      node.fieldValues[f.name] = f.defaultValue;
    }
    return BlockWidget(node: node);
  }
}
