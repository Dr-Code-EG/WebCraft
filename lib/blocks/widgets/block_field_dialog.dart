import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../model/block_node.dart';
import '../model/block_spec.dart';
import '../model/block_workspace.dart';

/// Opens an editor for a single block field. Returns the new value, or null
/// when cancelled.
Future<String?> editBlockField(
  BuildContext context, {
  required BlockNode node,
  required BlockFieldSpec field,
  required BlockWorkspace workspace,
}) async {
  final current = node.fieldValues[field.name] ?? field.defaultValue;
  switch (field.kind) {
    case BlockFieldKind.text:
      return _editText(context, field, current: current, multiline: false);
    case BlockFieldKind.number:
      return _editNumber(context, field, current: current);
    case BlockFieldKind.dropdown:
      return _editDropdown(context, field, current: current);
    case BlockFieldKind.color:
      return _editColor(context, field, current: current);
    case BlockFieldKind.element:
      return _editText(context, field, current: current);
    case BlockFieldKind.variable:
      return _editVariable(context, field, workspace, current: current);
  }
}

Future<String?> _editText(
  BuildContext context,
  BlockFieldSpec field, {
  String current = '',
  bool multiline = false,
}) async {
  final controller = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(field.name),
      content: TextField(
        controller: controller,
        autofocus: true,
        maxLines: multiline ? 4 : 1,
        decoration: InputDecoration(
          hintText: field.placeholder.isEmpty ? field.name : field.placeholder,
          border: const OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<String?> _editNumber(
  BuildContext context,
  BlockFieldSpec field, {
  String current = '',
}) async {
  final controller = TextEditingController(text: current);
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(field.name),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(
            decimal: true, signed: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[-0-9.]')),
        ],
        decoration: const InputDecoration(border: OutlineInputBorder()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, controller.text),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<String?> _editDropdown(
  BuildContext context,
  BlockFieldSpec field, {
  String current = '',
}) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(field.name),
      children: [
        for (final opt in field.options)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, opt),
            child: Row(
              children: [
                Icon(
                  opt == current
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(opt),
              ],
            ),
          ),
      ],
    ),
  );
}

const _kSwatches = <String>[
  '#111827', '#374151', '#6B7280', '#9CA3AF', '#D1D5DB', '#F3F4F6', '#FFFFFF',
  '#EF4444', '#F97316', '#F59E0B', '#FACC15', '#84CC16', '#22C55E', '#10B981',
  '#06B6D4', '#0EA5E9', '#3B82F6', '#6366F1', '#8B5CF6', '#A855F7', '#EC4899',
];

Future<String?> _editColor(
  BuildContext context,
  BlockFieldSpec field, {
  String current = '',
}) async {
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(field.name),
      content: SizedBox(
        width: 280,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final hex in _kSwatches)
              GestureDetector(
                onTap: () => Navigator.pop(ctx, hex),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Color(int.parse(hex.substring(1), radix: 16) +
                        0xFF000000),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black12),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancel'),
        ),
      ],
    ),
  );
}

Future<String?> _editVariable(
  BuildContext context,
  BlockFieldSpec field,
  BlockWorkspace workspace, {
  String current = '',
}) async {
  if (workspace.variables.isEmpty) {
    return _editText(context, field, current: current);
  }
  return showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(field.name),
      children: [
        for (final v in workspace.variables)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, v.name),
            child: Row(
              children: [
                Icon(Icons.tag, size: 16, color: Theme.of(ctx).colorScheme.primary),
                const SizedBox(width: 8),
                Text(v.name),
                const SizedBox(width: 8),
                Text(
                  '(${v.type.id})',
                  style: TextStyle(
                    color: Theme.of(ctx).colorScheme.outline,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}
