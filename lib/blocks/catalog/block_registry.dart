import 'package:flutter/material.dart';

import '../model/block_spec.dart';
import '../model/block_types.dart';

/// Singleton catalog of all known [BlockSpec]s. The catalog is seeded once
/// at startup and looked up by spec id from instance nodes.
class BlockRegistry {
  BlockRegistry._();
  static final BlockRegistry instance = BlockRegistry._();

  final Map<String, BlockSpec> _specs = {};

  Iterable<BlockSpec> get all => _specs.values;

  /// Group specs by category in the toolbox.
  List<BlockSpec> byCategory(BlockCategory cat) =>
      _specs.values.where((s) => s.category == cat).toList(growable: false);

  BlockSpec? lookup(String id) => _specs[id];

  void register(BlockSpec spec) {
    _specs[spec.id] = spec;
  }

  /// Seed the registry with the block set shipped in this build.
  void seedDefaults() {
    if (_specs.isNotEmpty) return;
    for (final s in _seed) {
      register(s);
    }
  }
}

/// Sketchware-style category palette. Each category gets its own hue so the
/// rendered blocks are easy to scan.
const Map<BlockCategory, Color> kCategoryColors = {
  BlockCategory.events: Color(0xFFEAB308), // yellow
  BlockCategory.variables: Color(0xFFEF4444), // red
  BlockCategory.logic: Color(0xFFF59E0B), // amber
  BlockCategory.math: Color(0xFF3B82F6), // blue
  BlockCategory.text: Color(0xFF10B981), // emerald
  BlockCategory.lists: Color(0xFFA855F7), // violet
  BlockCategory.dom: Color(0xFF8B5CF6), // purple
  BlockCategory.forms: Color(0xFF22C55E), // green
  BlockCategory.http: Color(0xFF0EA5E9), // sky
  BlockCategory.storage: Color(0xFF14B8A6), // teal
  BlockCategory.animation: Color(0xFFEC4899), // pink
  BlockCategory.functions: Color(0xFF6366F1), // indigo
};

Color colorFor(BlockSpec spec) =>
    spec.color ?? kCategoryColors[spec.category] ?? const Color(0xFF6B7280);

// ---------------------------------------------------------------------------
// Seed catalog (Phase B0). Intentionally small — the goal is to prove the
// rendering / data-model end-to-end. Phases B4+ flesh this out.
// ---------------------------------------------------------------------------

const List<BlockSpec> _seed = [
  // ---- Events (hat blocks)
  BlockSpec(
    id: 'on_page_load',
    category: BlockCategory.events,
    shape: BlockShape.hat,
    returnType: BlockType.voidT,
    template: 'When page loaded',
  ),
  BlockSpec(
    id: 'on_click',
    category: BlockCategory.events,
    shape: BlockShape.hat,
    returnType: BlockType.voidT,
    template: 'When %target clicked',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),
  BlockSpec(
    id: 'on_change',
    category: BlockCategory.events,
    shape: BlockShape.hat,
    returnType: BlockType.voidT,
    template: 'When %target changed',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),
  BlockSpec(
    id: 'on_submit',
    category: BlockCategory.events,
    shape: BlockShape.hat,
    returnType: BlockType.voidT,
    template: 'When %target submitted',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),
  BlockSpec(
    id: 'on_interval',
    category: BlockCategory.events,
    shape: BlockShape.hat,
    returnType: BlockType.voidT,
    template: 'Every %ms ms',
    fields: [
      BlockFieldSpec(
        name: 'ms',
        kind: BlockFieldKind.number,
        defaultValue: '1000',
      ),
    ],
  ),

  // ---- Variables
  BlockSpec(
    id: 'set_var',
    category: BlockCategory.variables,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'set %name to %value',
    fields: [
      BlockFieldSpec(
        name: 'name',
        kind: BlockFieldKind.variable,
        placeholder: 'name',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'value', accepts: BlockType.any),
    ],
  ),
  BlockSpec(
    id: 'get_var',
    category: BlockCategory.variables,
    shape: BlockShape.expression,
    returnType: BlockType.any,
    template: '%name',
    fields: [
      BlockFieldSpec(
        name: 'name',
        kind: BlockFieldKind.variable,
        placeholder: 'name',
      ),
    ],
  ),

  // ---- Math
  BlockSpec(
    id: 'number_literal',
    category: BlockCategory.math,
    shape: BlockShape.expression,
    returnType: BlockType.number,
    template: '%value',
    fields: [
      BlockFieldSpec(
        name: 'value',
        kind: BlockFieldKind.number,
        defaultValue: '0',
      ),
    ],
  ),
  BlockSpec(
    id: 'math_binop',
    category: BlockCategory.math,
    shape: BlockShape.expression,
    returnType: BlockType.number,
    template: '%a %op %b',
    fields: [
      BlockFieldSpec(
        name: 'op',
        kind: BlockFieldKind.dropdown,
        options: ['+', '-', '×', '÷', '%'],
        defaultValue: '+',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'a', accepts: BlockType.number),
      BlockSlotSpec(name: 'b', accepts: BlockType.number),
    ],
  ),

  // ---- Text
  BlockSpec(
    id: 'text_literal',
    category: BlockCategory.text,
    shape: BlockShape.expression,
    returnType: BlockType.text,
    template: '"%value"',
    fields: [
      BlockFieldSpec(
        name: 'value',
        kind: BlockFieldKind.text,
        placeholder: 'text',
      ),
    ],
  ),

  // ---- Logic
  BlockSpec(
    id: 'if_else',
    category: BlockCategory.logic,
    shape: BlockShape.cBlock,
    returnType: BlockType.voidT,
    template: 'if %cond',
    slots: [
      BlockSlotSpec(name: 'cond', accepts: BlockType.boolean),
    ],
    mouths: [
      BlockMouthSpec(name: 'then'),
      BlockMouthSpec(name: 'else'),
    ],
  ),
  BlockSpec(
    id: 'compare',
    category: BlockCategory.logic,
    shape: BlockShape.expression,
    returnType: BlockType.boolean,
    template: '%a %op %b',
    fields: [
      BlockFieldSpec(
        name: 'op',
        kind: BlockFieldKind.dropdown,
        options: ['==', '!=', '<', '<=', '>', '>='],
        defaultValue: '==',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'a', accepts: BlockType.any),
      BlockSlotSpec(name: 'b', accepts: BlockType.any),
    ],
  ),

  // ---- DOM
  BlockSpec(
    id: 'dom_set_text',
    category: BlockCategory.dom,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'set %target text to %value',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'value', accepts: BlockType.text),
    ],
  ),
  BlockSpec(
    id: 'dom_get_value',
    category: BlockCategory.dom,
    shape: BlockShape.expression,
    returnType: BlockType.text,
    template: 'value of %target',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),
  BlockSpec(
    id: 'dom_set_style',
    category: BlockCategory.dom,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'set %target style %prop to %value',
    fields: [
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
      BlockFieldSpec(
        name: 'prop',
        kind: BlockFieldKind.text,
        defaultValue: 'color',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'value', accepts: BlockType.text),
    ],
  ),
  BlockSpec(
    id: 'dom_show_hide',
    category: BlockCategory.dom,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: '%action %target',
    fields: [
      BlockFieldSpec(
        name: 'action',
        kind: BlockFieldKind.dropdown,
        options: ['show', 'hide'],
        defaultValue: 'show',
      ),
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),
  BlockSpec(
    id: 'dom_add_class',
    category: BlockCategory.dom,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: '%action class %name on %target',
    fields: [
      BlockFieldSpec(
        name: 'action',
        kind: BlockFieldKind.dropdown,
        options: ['add', 'remove', 'toggle'],
        defaultValue: 'add',
      ),
      BlockFieldSpec(
        name: 'name',
        kind: BlockFieldKind.text,
        defaultValue: 'active',
      ),
      BlockFieldSpec(
        name: 'target',
        kind: BlockFieldKind.element,
        defaultValue: 'self',
      ),
    ],
  ),

  // ---- Loops
  BlockSpec(
    id: 'while_loop',
    category: BlockCategory.logic,
    shape: BlockShape.cBlock,
    returnType: BlockType.voidT,
    template: 'while %cond',
    slots: [
      BlockSlotSpec(name: 'cond', accepts: BlockType.boolean),
    ],
    mouths: [
      BlockMouthSpec(name: 'body'),
    ],
  ),
  BlockSpec(
    id: 'repeat_n',
    category: BlockCategory.logic,
    shape: BlockShape.cBlock,
    returnType: BlockType.voidT,
    template: 'repeat %count times',
    slots: [
      BlockSlotSpec(name: 'count', accepts: BlockType.number),
    ],
    mouths: [
      BlockMouthSpec(name: 'body'),
    ],
  ),
  BlockSpec(
    id: 'logic_andor',
    category: BlockCategory.logic,
    shape: BlockShape.expression,
    returnType: BlockType.boolean,
    template: '%a %op %b',
    fields: [
      BlockFieldSpec(
        name: 'op',
        kind: BlockFieldKind.dropdown,
        options: ['and', 'or'],
        defaultValue: 'and',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'a', accepts: BlockType.boolean),
      BlockSlotSpec(name: 'b', accepts: BlockType.boolean),
    ],
  ),
  BlockSpec(
    id: 'logic_not',
    category: BlockCategory.logic,
    shape: BlockShape.expression,
    returnType: BlockType.boolean,
    template: 'not %a',
    slots: [
      BlockSlotSpec(name: 'a', accepts: BlockType.boolean),
    ],
  ),

  // ---- Text helpers
  BlockSpec(
    id: 'text_concat',
    category: BlockCategory.text,
    shape: BlockShape.expression,
    returnType: BlockType.text,
    template: '%a join %b',
    slots: [
      BlockSlotSpec(name: 'a', accepts: BlockType.any),
      BlockSlotSpec(name: 'b', accepts: BlockType.any),
    ],
  ),
  BlockSpec(
    id: 'text_length',
    category: BlockCategory.text,
    shape: BlockShape.expression,
    returnType: BlockType.number,
    template: 'length of %s',
    slots: [
      BlockSlotSpec(name: 's', accepts: BlockType.text),
    ],
  ),

  // ---- Lists
  BlockSpec(
    id: 'list_create',
    category: BlockCategory.lists,
    shape: BlockShape.expression,
    returnType: BlockType.list,
    template: 'empty list',
  ),
  BlockSpec(
    id: 'list_add',
    category: BlockCategory.lists,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'add %item to %list',
    slots: [
      BlockSlotSpec(name: 'item', accepts: BlockType.any),
      BlockSlotSpec(name: 'list', accepts: BlockType.list),
    ],
  ),
  BlockSpec(
    id: 'list_length',
    category: BlockCategory.lists,
    shape: BlockShape.expression,
    returnType: BlockType.number,
    template: 'length of %list',
    slots: [
      BlockSlotSpec(name: 'list', accepts: BlockType.list),
    ],
  ),
  BlockSpec(
    id: 'list_get',
    category: BlockCategory.lists,
    shape: BlockShape.expression,
    returnType: BlockType.any,
    template: 'item %i of %list',
    slots: [
      BlockSlotSpec(name: 'i', accepts: BlockType.number),
      BlockSlotSpec(name: 'list', accepts: BlockType.list),
    ],
  ),

  // ---- HTTP
  BlockSpec(
    id: 'http_get',
    category: BlockCategory.http,
    shape: BlockShape.expression,
    returnType: BlockType.text,
    template: 'fetch %url',
    slots: [
      BlockSlotSpec(name: 'url', accepts: BlockType.text),
    ],
  ),

  // ---- Storage
  BlockSpec(
    id: 'storage_set',
    category: BlockCategory.storage,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'save %key = %value',
    fields: [
      BlockFieldSpec(
        name: 'key',
        kind: BlockFieldKind.text,
        defaultValue: 'key',
      ),
    ],
    slots: [
      BlockSlotSpec(name: 'value', accepts: BlockType.any),
    ],
  ),
  BlockSpec(
    id: 'storage_get',
    category: BlockCategory.storage,
    shape: BlockShape.expression,
    returnType: BlockType.text,
    template: 'load %key',
    fields: [
      BlockFieldSpec(
        name: 'key',
        kind: BlockFieldKind.text,
        defaultValue: 'key',
      ),
    ],
  ),

  // ---- Animation
  BlockSpec(
    id: 'wait_ms',
    category: BlockCategory.animation,
    shape: BlockShape.statement,
    returnType: BlockType.voidT,
    template: 'wait %ms ms',
    fields: [
      BlockFieldSpec(
        name: 'ms',
        kind: BlockFieldKind.number,
        defaultValue: '500',
      ),
    ],
  ),

  // ---- Functions
  BlockSpec(
    id: 'fn_return',
    category: BlockCategory.functions,
    shape: BlockShape.cap,
    returnType: BlockType.voidT,
    template: 'return %value',
    slots: [
      BlockSlotSpec(name: 'value', accepts: BlockType.any),
    ],
  ),
];
