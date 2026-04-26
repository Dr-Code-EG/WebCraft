import '../model/block_node.dart';
import '../model/block_spec.dart';

/// Payload used while dragging a block. A drag that originates from the
/// toolbox carries a [spec] (so the drop site instantiates a fresh node);
/// a drag from the workspace carries the existing [node] (so the drop site
/// re-attaches it after detaching).
class BlockDragPayload {
  BlockDragPayload.fromToolbox(this.spec) : node = null;
  BlockDragPayload.fromWorkspace(this.node) : spec = null;

  final BlockSpec? spec;
  final BlockNode? node;

  bool get isFromToolbox => spec != null;
}
