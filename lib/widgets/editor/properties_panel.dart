import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surfaceContainerLowest,
      child: Consumer<EditorProvider>(
        builder: (context, ed, _) {
          final el = ed.selectedElement;
          if (el == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tune, size: 48, color: cs.outline),
                    const SizedBox(height: 12),
                    Text(l10n.noElementSelected,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(
                      l10n.selectAnElement,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          }
          return _Editor(element: el);
        },
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.element});
  final ElementNode element;

  @override
  Widget build(BuildContext context) {
    final ed = context.read<EditorProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Header(element: element),
        const SizedBox(height: 16),
        ..._contentFields(context, ed),
        const Divider(height: 32),
        _Section(title: AppLocalizations.of(context)!.propBackground),
        ..._styleFields(context, ed),
      ],
    );
  }

  List<Widget> _contentFields(BuildContext context, EditorProvider ed) {
    final l10n = AppLocalizations.of(context)!;
    final type = element.type;
    final fields = <Widget>[];

    void addProp(String label, String key, {int maxLines = 1}) {
      fields.add(_PropField(
        label: label,
        value: element.props[key] ?? '',
        maxLines: maxLines,
        onChanged: (v) => ed.updateProp(element.id, key, v),
      ));
    }

    switch (type) {
      case ElementType.heading:
        addProp(l10n.propText, 'text');
        fields.add(_DropdownField(
          label: 'Level',
          value: element.props['level'] ?? 'h1',
          options: const ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
          onChanged: (v) => ed.updateProp(element.id, 'level', v),
        ));
        break;
      case ElementType.paragraph:
      case ElementType.text:
      case ElementType.button:
        addProp(l10n.propText, 'text', maxLines: 3);
        break;
      case ElementType.link:
        addProp(l10n.propText, 'text');
        addProp(l10n.propLink, 'href');
        break;
      case ElementType.image:
        addProp(l10n.propImageUrl, 'src');
        addProp(l10n.propAltText, 'alt');
        break;
      case ElementType.input:
        addProp(l10n.propPlaceholder, 'placeholder');
        addProp('name', 'name');
        fields.add(_DropdownField(
          label: 'type',
          value: element.props['type'] ?? 'text',
          options: const [
            'text',
            'email',
            'password',
            'number',
            'tel',
            'url',
            'date'
          ],
          onChanged: (v) => ed.updateProp(element.id, 'type', v),
        ));
        break;
      case ElementType.textarea:
        addProp(l10n.propPlaceholder, 'placeholder');
        addProp('name', 'name');
        addProp('rows', 'rows');
        break;
      case ElementType.form:
        addProp('action', 'action');
        fields.add(_DropdownField(
          label: 'method',
          value: element.props['method'] ?? 'post',
          options: const ['post', 'get'],
          onChanged: (v) => ed.updateProp(element.id, 'method', v),
        ));
        break;
      case ElementType.list:
        fields.add(_DropdownField(
          label: 'list type',
          value: (element.props['ordered'] ?? 'false') == 'true'
              ? 'ordered'
              : 'unordered',
          options: const ['unordered', 'ordered'],
          onChanged: (v) => ed.updateProp(
              element.id, 'ordered', v == 'ordered' ? 'true' : 'false'),
        ));
        break;
      case ElementType.video:
        addProp('src', 'src');
        break;
      default:
        break;
    }

    addProp(l10n.propId, 'id');
    addProp(l10n.propClass, 'class');
    return fields;
  }

  List<Widget> _styleFields(BuildContext context, EditorProvider ed) {
    final l10n = AppLocalizations.of(context)!;
    final fields = <Widget>[];

    void addStyle(String label, String key, {String? hint}) {
      fields.add(_PropField(
        label: label,
        value: element.style[key] ?? '',
        hint: hint,
        onChanged: (v) => ed.updateStyle(element.id, key, v),
      ));
    }

    addStyle(l10n.propBackground, 'background', hint: '#ffffff');
    addStyle(l10n.propColor, 'color', hint: '#111827');
    addStyle(l10n.propPadding, 'padding', hint: '16px');
    addStyle(l10n.propMargin, 'margin', hint: '0');
    addStyle(l10n.propWidth, 'width', hint: '100%');
    addStyle(l10n.propHeight, 'height', hint: 'auto');
    addStyle(l10n.propFontSize, 'font-size', hint: '16px');
    addStyle(l10n.propBorderRadius, 'border-radius', hint: '8px');
    addStyle(l10n.propBorder, 'border', hint: '1px solid #d1d5db');

    fields.add(_DropdownField(
      label: l10n.propFontWeight,
      value: element.style['font-weight'] ?? 'normal',
      options: const ['normal', '500', '600', '700', 'bold'],
      onChanged: (v) => ed.updateStyle(element.id, 'font-weight', v),
    ));
    fields.add(_DropdownField(
      label: l10n.propTextAlign,
      value: element.style['text-align'] ?? 'left',
      options: const ['left', 'center', 'right', 'justify'],
      onChanged: (v) => ed.updateStyle(element.id, 'text-align', v),
    ));

    return fields;
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.element});
  final ElementNode element;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            element.type.id,
            style: TextStyle(
              color: cs.onPrimaryContainer,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          AppLocalizations.of(context)!.properties,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _PropField extends StatefulWidget {
  const _PropField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? hint;
  final int maxLines;

  @override
  State<_PropField> createState() => _PropFieldState();
}

class _PropFieldState extends State<_PropField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(covariant _PropField old) {
    super.didUpdateWidget(old);
    if (widget.value != _controller.text) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controller,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          DropdownButtonFormField<String>(
            value: options.contains(value) ? value : options.first,
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            onChanged: (v) {
              if (v != null) onChanged(v);
            },
            decoration: const InputDecoration(
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
