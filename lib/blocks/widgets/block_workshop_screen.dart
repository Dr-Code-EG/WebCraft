import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_workspace.dart';
import '../state/block_workspace_controller.dart';
import 'block_drag_payload.dart';
import 'block_field_dialog.dart';
import 'blocks_toolbox.dart';
import 'interactive_block_tree.dart';

/// Standalone block-editor sandbox: toolbox on one side, free-form workspace
/// canvas on the other. Phase B1 (drag/snap) + B2 (toolbox) + B3 (field
/// editing) come together here.
class BlockWorkshopScreen extends StatefulWidget {
  const BlockWorkshopScreen({super.key, this.initial});

  final BlockWorkspace? initial;

  @override
  State<BlockWorkshopScreen> createState() => _BlockWorkshopScreenState();
}

class _BlockWorkshopScreenState extends State<BlockWorkshopScreen> {
  late final BlockWorkspaceController _controller;

  @override
  void initState() {
    super.initState();
    _controller = BlockWorkspaceController(
      widget.initial ?? BlockWorkspace(id: 'workshop'),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Block Workshop'),
        actions: [
          IconButton(
            tooltip: 'Variables',
            icon: const Icon(Icons.tag),
            onPressed: _openVariablesSheet,
          ),
          IconButton(
            tooltip: 'Reset',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _controller.workspace.roots.clear();
                _controller.workspace.variables.clear();
                _controller.select(null);
              });
            },
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final wide = c.maxWidth >= 720;
          if (wide) {
            return Row(
              children: [
                SizedBox(
                  width: 280,
                  child: BlocksToolbox(
                    onTapBlock: _addAtDefaultPosition,
                  ),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: _buildCanvas(cs)),
              ],
            );
          }
          // Phone: workspace on top, toolbox bottom sheet
          return Column(
            children: [
              Expanded(child: _buildCanvas(cs)),
              const Divider(height: 1),
              SizedBox(
                height: 240,
                child: BlocksToolbox(
                  onTapBlock: _addAtDefaultPosition,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          if (_controller.selectedId == null) return const SizedBox.shrink();
          return FloatingActionButton.extended(
            backgroundColor: cs.errorContainer,
            foregroundColor: cs.onErrorContainer,
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
            onPressed: () {
              _controller.delete(_controller.selectedId!);
            },
          );
        },
      ),
    );
  }

  Widget _buildCanvas(ColorScheme cs) {
    return Container(
      color: cs.surfaceContainerHigh,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return DragTarget<BlockDragPayload>(
            onWillAcceptWithDetails: (_) => true,
            onAcceptWithDetails: (d) {
              // Compute drop offset relative to the canvas RenderBox.
              final box = context.findRenderObject() as RenderBox?;
              final local = box?.globalToLocal(d.offset) ?? d.offset;
              if (d.data.isFromToolbox) {
                final node = BlockNode(specId: d.data.spec!.id);
                _controller.addRootAt(node, local.dx, local.dy);
              } else {
                _controller.moveToRoot(d.data.node!.id, local.dx, local.dy);
              }
            },
            builder: (context, candidate, rejected) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _controller.select(null),
                child: SizedBox.expand(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: SizedBox(
                        width: 1600,
                        height: 2000,
                        child: Stack(
                          children: [
                            if (_controller.workspace.roots.isEmpty)
                              const Positioned(
                                left: 24,
                                top: 24,
                                child: _EmptyHint(),
                              ),
                            for (final root in _controller.workspace.roots)
                              Positioned(
                                left: root.x,
                                top: root.y,
                                child: InteractiveBlockTree(
                                  root: root,
                                  controller: _controller,
                                  onEditField: (node, field) =>
                                      editBlockField(
                                    context,
                                    node: node,
                                    field: field,
                                    workspace: _controller.workspace,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _addAtDefaultPosition(BlockSpec spec) {
    final node = BlockNode(specId: spec.id);
    final n = _controller.workspace.roots.length;
    _controller.addRootAt(node, 24 + (n % 4) * 12.0, 24 + n * 70.0);
  }

  Future<void> _openVariablesSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return _VariablesSheet(controller: _controller);
      },
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 320,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: cs.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.primary.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.extension_outlined, color: cs.primary),
              const SizedBox(width: 8),
              Text(
                'Block Workshop',
                style: TextStyle(
                  color: cs.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Tap a block in the toolbox to add it to the canvas.\n'
            '• Drag blocks onto each other to snap them in chains.\n'
            '• Drop expression blocks into typed slots.\n'
            '• Long-press to drag, then move freely.',
            style: TextStyle(fontSize: 12.5, height: 1.6),
          ),
        ],
      ),
    );
  }
}

class _VariablesSheet extends StatefulWidget {
  const _VariablesSheet({required this.controller});
  final BlockWorkspaceController controller;

  @override
  State<_VariablesSheet> createState() => _VariablesSheetState();
}

class _VariablesSheetState extends State<_VariablesSheet> {
  final _newName = TextEditingController();

  @override
  void dispose() {
    _newName.dispose();
    super.dispose();
  }

  Future<void> _confirmRemoveVariable(
      BuildContext context, String name) async {
    final l10n = AppLocalizations.of(context)!;
    final usages = widget.controller.countVariableUsages(name);
    if (usages == 0) {
      widget.controller.removeVariable(name);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: Text(l10n.variableInUse(usages)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.errorContainer),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.deleteAnyway),
          ),
        ],
      ),
    );
    if (ok == true) widget.controller.removeVariable(name);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final vars = widget.controller.workspace.variables;
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Variables',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              if (vars.isEmpty)
                const Text('No variables yet.',
                    style: TextStyle(color: Colors.grey)),
              for (final v in vars)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.tag),
                  title: Text(v.name),
                  subtitle: Text(v.type.id),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    onPressed: () => _confirmRemoveVariable(context, v.name),
                  ),
                ),
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newName,
                      decoration: const InputDecoration(
                        hintText: 'Variable name',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      final name = _newName.text;
                      if (widget.controller.addVariable(name)) {
                        _newName.clear();
                      }
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
