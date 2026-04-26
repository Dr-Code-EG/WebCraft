/// Type system for block expressions / slots.
///
/// Slots accept exactly one of these types (or [any]). The type system is
/// intentionally small and structural — there is no inheritance.
enum BlockType {
  /// No value (statement blocks).
  voidT,
  number,
  text,
  boolean,
  list,

  /// Reference to a UI element node by its id.
  element,

  /// Anything goes (compatibility wildcard, e.g. variable values).
  any;

  String get id => switch (this) {
        BlockType.voidT => 'void',
        BlockType.number => 'number',
        BlockType.text => 'text',
        BlockType.boolean => 'boolean',
        BlockType.list => 'list',
        BlockType.element => 'element',
        BlockType.any => 'any',
      };

  static BlockType parse(String? id) {
    return BlockType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => BlockType.any,
    );
  }

  /// `true` when a block returning [other] is acceptable in a slot of `this`.
  bool accepts(BlockType other) {
    if (this == BlockType.any || other == BlockType.any) return true;
    return this == other;
  }
}

/// Visual / structural shape of a block — drives both rendering (notches)
/// and the parser/compiler.
enum BlockShape {
  /// "When …" — top of an event stack. Only has a bottom notch.
  hat,

  /// Rectangular statement with both top and bottom notches.
  statement,

  /// C-shaped statement that wraps an inner stack (`if`, `while`, `for`).
  cBlock,

  /// Pointed/oval expression — slots into another block, returns a value.
  expression,

  /// Cap statement — has a top notch but no bottom (`return`, `break`).
  cap;

  String get id => switch (this) {
        BlockShape.hat => 'hat',
        BlockShape.statement => 'statement',
        BlockShape.cBlock => 'c_block',
        BlockShape.expression => 'expression',
        BlockShape.cap => 'cap',
      };

  static BlockShape parse(String? id) {
    return BlockShape.values.firstWhere(
      (e) => e.id == id,
      orElse: () => BlockShape.statement,
    );
  }

  /// Whether the shape can have a block attached _after_ it in a stack.
  bool get hasNextNotch =>
      this == BlockShape.hat ||
      this == BlockShape.statement ||
      this == BlockShape.cBlock;

  /// Whether the shape can be attached _below_ another block in a stack.
  bool get hasPrevNotch =>
      this == BlockShape.statement ||
      this == BlockShape.cBlock ||
      this == BlockShape.cap;
}

/// Top-level block category — only used for grouping in the toolbox and
/// for picking a default color.
enum BlockCategory {
  events,
  variables,
  logic,
  math,
  text,
  lists,
  dom,
  forms,
  http,
  storage,
  animation,
  functions;

  String get id => name;

  static BlockCategory parse(String? id) {
    return BlockCategory.values.firstWhere(
      (e) => e.id == id,
      orElse: () => BlockCategory.logic,
    );
  }
}
