import 'package:flutter/widgets.dart';

import 'block_types.dart';

/// A field is an inline editable value embedded in the block (text input,
/// number input, dropdown, color picker, …). Fields are part of the block
/// definition and never accept other blocks.
enum BlockFieldKind { text, number, dropdown, color, element, variable }

class BlockFieldSpec {
  const BlockFieldSpec({
    required this.name,
    required this.kind,
    this.options = const [],
    this.defaultValue = '',
    this.placeholder = '',
  });

  final String name;
  final BlockFieldKind kind;

  /// For [BlockFieldKind.dropdown]: list of allowed values. The label shown to
  /// the user is taken from localization based on `'block.<specId>.<name>.<value>'`.
  final List<String> options;
  final String defaultValue;
  final String placeholder;

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.name,
        if (options.isNotEmpty) 'options': options,
        if (defaultValue.isNotEmpty) 'default': defaultValue,
      };
}

/// A slot accepts a single expression block of a given [accepts] type.
class BlockSlotSpec {
  const BlockSlotSpec({required this.name, required this.accepts});
  final String name;
  final BlockType accepts;

  Map<String, dynamic> toJson() => {
        'name': name,
        'accepts': accepts.id,
      };
}

/// A C-block has one or more "mouths" — vertical pockets that hold inner
/// statement stacks (e.g. an `if` block has a `then` mouth and an
/// optional `else` mouth).
class BlockMouthSpec {
  const BlockMouthSpec({required this.name});
  final String name;

  Map<String, dynamic> toJson() => {'name': name};
}

/// Static, immutable definition of a block kind. Plays the role of a class
/// in OOP — block instances ([BlockNode]) reference one of these by id.
@immutable
class BlockSpec {
  const BlockSpec({
    required this.id,
    required this.category,
    required this.shape,
    required this.returnType,
    required this.template,
    this.fields = const [],
    this.slots = const [],
    this.mouths = const [],
    this.color,
  });

  /// Stable identifier (`set_var`, `if`, `http_get`, …).
  final String id;
  final BlockCategory category;
  final BlockShape shape;

  /// Return type for [BlockShape.expression]; ignored for other shapes
  /// (statements always return [BlockType.voidT]).
  final BlockType returnType;

  /// Display template with `%FIELD` and `%SLOT` placeholders. Examples:
  /// - `set %name to %value`
  /// - `if %cond`
  /// - `%a + %b`
  ///
  /// Placeholder names match either a field or slot name.
  final String template;

  final List<BlockFieldSpec> fields;
  final List<BlockSlotSpec> slots;
  final List<BlockMouthSpec> mouths;

  /// Override the default category color.
  final Color? color;

  /// Find a field/slot/mouth by name (returns null when not present).
  BlockFieldSpec? field(String name) {
    for (final f in fields) {
      if (f.name == name) return f;
    }
    return null;
  }

  BlockSlotSpec? slot(String name) {
    for (final s in slots) {
      if (s.name == name) return s;
    }
    return null;
  }

  BlockMouthSpec? mouth(String name) {
    for (final m in mouths) {
      if (m.name == name) return m;
    }
    return null;
  }
}
