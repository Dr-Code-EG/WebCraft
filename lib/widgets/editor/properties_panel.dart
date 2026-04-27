import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../blocks/catalog/block_registry.dart';
import '../../blocks/model/block_node.dart';
import '../../blocks/model/block_types.dart';
import '../../blocks/model/block_workspace.dart';
import '../../blocks/widgets/block_workshop_screen.dart';
import '../../models/element_node.dart';
import '../../state/editor_provider.dart';

/// Sketchware-style bottom panel: a horizontal strip of property chips
/// (one per editable attribute) for the currently selected element. Tapping
/// a chip opens a focused dialog to edit that single property.
class PropertiesPanel extends StatelessWidget {
  const PropertiesPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerLowest,
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.15),
      child: Consumer<EditorProvider>(
        builder: (context, ed, _) {
          final el = ed.selectedElement;
          if (el == null) {
            return _EmptyState(l10n: l10n);
          }
          return _Editor(element: el);
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 72,
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.touch_app_outlined, size: 18, color: cs.outline),
            const SizedBox(width: 8),
            Text(
              l10n.selectElement,
              style: TextStyle(color: cs.onSurfaceVariant, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({required this.element});
  final ElementNode element;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final ed = context.read<EditorProvider>();

    final contentChips = _contentChips(context, ed, l10n);
    final styleChips = _styleChips(context, ed, l10n);
    final layoutChips = _layoutChips(context, ed, l10n);

    return DefaultTabController(
      length: 4,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(element: element, ed: ed),
          SizedBox(
            height: 38,
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: cs.primary,
              unselectedLabelColor: cs.onSurfaceVariant,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
              tabs: [
                Tab(text: l10n.tabContent),
                Tab(text: l10n.tabStyle),
                Tab(text: l10n.tabLayout),
                Tab(text: l10n.tabLogic),
              ],
            ),
          ),
          SizedBox(
            height: 92,
            child: TabBarView(
              children: [
                _ChipsRow(chips: contentChips, emptyText: l10n.noContentProps),
                _ChipsRow(chips: styleChips, emptyText: l10n.tapToEdit),
                _ChipsRow(chips: layoutChips, emptyText: l10n.tapToEdit),
                _LogicTab(element: element, ed: ed),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----- chip builders -----

  List<_PropChip> _contentChips(
      BuildContext context, EditorProvider ed, AppLocalizations l10n) {
    final chips = <_PropChip>[];
    void addText(String label, String key, {int maxLines = 1}) {
      chips.add(_PropChip(
        icon: Icons.edit_outlined,
        label: label,
        value: element.props[key] ?? '',
        onTap: () => _editTextDialog(
          context,
          title: label,
          initial: element.props[key] ?? '',
          maxLines: maxLines,
          onSubmit: (v) => ed.updateProp(element.id, key, v),
        ),
      ));
    }

    void addEnum(String label, String key, List<String> options,
        {String? defaultValue}) {
      chips.add(_PropChip(
        icon: Icons.unfold_more_rounded,
        label: label,
        value: element.props[key] ?? defaultValue ?? '',
        onTap: () => _editEnumDialog(
          context,
          title: label,
          current: element.props[key] ?? defaultValue ?? options.first,
          options: options,
          onSubmit: (v) => ed.updateProp(element.id, key, v),
        ),
      ));
    }

    switch (element.type) {
      case ElementType.heading:
        addText(l10n.propText, 'text');
        addEnum('Level', 'level', const ['h1', 'h2', 'h3', 'h4', 'h5', 'h6'],
            defaultValue: 'h1');
        break;
      case ElementType.paragraph:
      case ElementType.text:
      case ElementType.button:
        addText(l10n.propText, 'text', maxLines: 4);
        break;
      case ElementType.link:
        addText(l10n.propText, 'text');
        addText(l10n.propLink, 'href');
        break;
      case ElementType.image:
        chips.add(_PropChip(
          icon: Icons.image_outlined,
          label: l10n.propImageUrl,
          value: _shortImage(element.props['src'] ?? ''),
          onTap: () => _pickImageOrUrl(context, ed, element, 'src'),
        ));
        addText(l10n.propAltText, 'alt');
        break;
      case ElementType.input:
        addText(l10n.propPlaceholder, 'placeholder');
        addText('Name', 'name');
        addEnum('Type', 'type',
            const ['text', 'email', 'password', 'number', 'tel', 'url', 'date'],
            defaultValue: 'text');
        break;
      case ElementType.textarea:
        addText(l10n.propPlaceholder, 'placeholder');
        addText('Name', 'name');
        addText('Rows', 'rows');
        break;
      case ElementType.form:
        addText('Action', 'action');
        addEnum('Method', 'method', const ['post', 'get'],
            defaultValue: 'post');
        break;
      case ElementType.list:
        addEnum('List type', 'ordered', const ['false', 'true'],
            defaultValue: 'false');
        break;
      case ElementType.video:
        addText('Source', 'src');
        break;
      default:
        break;
    }

    addText(l10n.propId, 'id');
    addText(l10n.propClass, 'class');
    return chips;
  }

  List<_PropChip> _styleChips(
      BuildContext context, EditorProvider ed, AppLocalizations l10n) {
    final chips = <_PropChip>[];

    void addColor(String label, String key, {String? hint}) {
      chips.add(_PropChip(
        icon: Icons.color_lens_outlined,
        label: label,
        value: element.style[key] ?? '',
        swatchColor: _parseColor(element.style[key]),
        onTap: () => _editColorDialog(
          context,
          title: label,
          initial: element.style[key] ?? '',
          onSubmit: (v) => ed.updateStyle(element.id, key, v),
        ),
      ));
    }

    void addSize(String label, String key, {String? hint}) {
      chips.add(_PropChip(
        icon: Icons.straighten_rounded,
        label: label,
        value: element.style[key] ?? '',
        onTap: () => _editTextDialog(
          context,
          title: label,
          initial: element.style[key] ?? '',
          hint: hint,
          onSubmit: (v) => ed.updateStyle(element.id, key, v),
        ),
      ));
    }

    void addEnum(String label, String key, List<String> options,
        {String? defaultValue, IconData? icon}) {
      chips.add(_PropChip(
        icon: icon ?? Icons.unfold_more_rounded,
        label: label,
        value: element.style[key] ?? defaultValue ?? '',
        onTap: () => _editEnumDialog(
          context,
          title: label,
          current: element.style[key] ?? defaultValue ?? options.first,
          options: options,
          onSubmit: (v) => ed.updateStyle(element.id, key, v),
        ),
      ));
    }

    addColor(l10n.propBackground, 'background', hint: '#ffffff');
    addColor(l10n.propColor, 'color', hint: '#111827');
    addSize(l10n.propFontSize, 'font-size', hint: '16px');
    addEnum(l10n.propFontWeight, 'font-weight',
        const ['normal', '500', '600', '700', 'bold'],
        defaultValue: 'normal', icon: Icons.format_bold_rounded);
    addEnum(l10n.propTextAlign, 'text-align',
        const ['left', 'center', 'right', 'justify'],
        defaultValue: 'left', icon: Icons.format_align_left_rounded);
    addSize(l10n.propBorderRadius, 'border-radius', hint: '8px');
    addSize(l10n.propBorder, 'border', hint: '1px solid #d1d5db');
    return chips;
  }

  List<_PropChip> _layoutChips(
      BuildContext context, EditorProvider ed, AppLocalizations l10n) {
    final chips = <_PropChip>[];

    void addSize(String label, String key, {String? hint}) {
      chips.add(_PropChip(
        icon: Icons.straighten_rounded,
        label: label,
        value: element.style[key] ?? '',
        onTap: () => _editTextDialog(
          context,
          title: label,
          initial: element.style[key] ?? '',
          hint: hint,
          onSubmit: (v) => ed.updateStyle(element.id, key, v),
        ),
      ));
    }

    void addBox(String label, String key) {
      chips.add(_PropChip(
        icon: Icons.fit_screen_rounded,
        label: label,
        value: element.style[key] ?? '',
        onTap: () => _editBoxModelDialog(
          context,
          title: label,
          initial: element.style[key] ?? '',
          onSubmit: (v) => ed.updateStyle(element.id, key, v),
        ),
      ));
    }

    addSize(l10n.propWidth, 'width', hint: '100%');
    addSize(l10n.propHeight, 'height', hint: 'auto');
    addBox(l10n.propPadding, 'padding');
    addBox(l10n.propMargin, 'margin');
    if (element.type.acceptsChildren) {
      addSize(l10n.propGap, 'gap', hint: '12px');
    }
    return chips;
  }

  // ----- dialogs -----

  Future<void> _editTextDialog(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> onSubmit,
    String? hint,
    int maxLines = 1,
  }) async {
    final controller = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.editProperty(title)),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: hint,
              border: const OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () {
                controller.text = '';
                Navigator.of(ctx).pop('');
              },
              child: Text(l10n.clear),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
    if (result != null) onSubmit(result);
  }

  Future<void> _editEnumDialog(
    BuildContext context, {
    required String title,
    required String current,
    required List<String> options,
    required ValueChanged<String> onSubmit,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.editProperty(title)),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          content: SizedBox(
            width: 280,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final o in options)
                  RadioListTile<String>(
                    dense: true,
                    title: Text(o),
                    value: o,
                    groupValue: current,
                    onChanged: (v) => Navigator.of(ctx).pop(v),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l10n.cancel),
            ),
          ],
        );
      },
    );
    if (result != null) onSubmit(result);
  }

  /// 4-side picker for `padding` / `margin` shorthand. Parses the existing
  /// CSS shorthand into top/right/bottom/left fields, then re-emits the
  /// shortest equivalent shorthand (1/2/3/4 values) on save.
  Future<void> _editBoxModelDialog(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> onSubmit,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    final initialSides = _parseBox(initial);
    final tCtl = TextEditingController(text: initialSides[0]);
    final rCtl = TextEditingController(text: initialSides[1]);
    final bCtl = TextEditingController(text: initialSides[2]);
    final lCtl = TextEditingController(text: initialSides[3]);
    var linked = initialSides[0] == initialSides[1] &&
        initialSides[0] == initialSides[2] &&
        initialSides[0] == initialSides[3];

    final result = await showDialog<String?>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSt) {
          Widget sideField(String label, TextEditingController c) {
            return SizedBox(
              width: 110,
              child: TextField(
                controller: c,
                onChanged: (v) {
                  if (linked) {
                    tCtl.text = v;
                    rCtl.text = v;
                    bCtl.text = v;
                    lCtl.text = v;
                  }
                },
                decoration: InputDecoration(
                  isDense: true,
                  labelText: label,
                  hintText: '0',
                  border: const OutlineInputBorder(),
                ),
              ),
            );
          }

          return AlertDialog(
            title: Text(l10n.editProperty(title)),
            content: SizedBox(
              width: 320,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(l10n.all),
                          value: linked,
                          onChanged: (v) {
                            setSt(() {
                              linked = v;
                              if (v) {
                                final shared = tCtl.text;
                                rCtl.text = shared;
                                bCtl.text = shared;
                                lCtl.text = shared;
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      sideField(l10n.top, tCtl),
                      sideField(l10n.right, rCtl),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      sideField(l10n.bottom, bCtl),
                      sideField(l10n.left, lCtl),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(null),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(''),
                child: Text(l10n.clear),
              ),
              FilledButton(
                onPressed: () {
                  final compact = _composeBox(
                    tCtl.text.trim(),
                    rCtl.text.trim(),
                    bCtl.text.trim(),
                    lCtl.text.trim(),
                  );
                  Navigator.of(ctx).pop(compact);
                },
                child: Text(l10n.done),
              ),
            ],
          );
        });
      },
    );
    if (result != null) onSubmit(result);
  }

  /// Parse a CSS shorthand value (`top right bottom left`, `tb rl`, etc) into
  /// 4 individual sides.
  static List<String> _parseBox(String raw) {
    final parts =
        raw.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    switch (parts.length) {
      case 0:
        return ['', '', '', ''];
      case 1:
        return [parts[0], parts[0], parts[0], parts[0]];
      case 2:
        return [parts[0], parts[1], parts[0], parts[1]];
      case 3:
        return [parts[0], parts[1], parts[2], parts[1]];
      default:
        return [parts[0], parts[1], parts[2], parts[3]];
    }
  }

  /// Compose the shortest CSS shorthand for the four sides.
  static String _composeBox(String t, String r, String b, String l) {
    if (t.isEmpty && r.isEmpty && b.isEmpty && l.isEmpty) return '';
    final tt = _withUnit(t);
    final rr = _withUnit(r);
    final bb = _withUnit(b);
    final ll = _withUnit(l);
    if (tt == rr && rr == bb && bb == ll) return tt;
    if (tt == bb && rr == ll) return '$tt $rr';
    if (rr == ll) return '$tt $rr $bb';
    return '$tt $rr $bb $ll';
  }

  /// If [v] looks like a bare number, append `px` for convenience.
  static String _withUnit(String v) {
    if (v.isEmpty) return '0';
    if (RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v)) return '${v}px';
    return v;
  }

  /// Shorten data URIs for display so the chip stays compact.
  static String _shortImage(String src) {
    if (src.isEmpty) return '';
    if (src.startsWith('data:')) return '(image)';
    return src;
  }

  /// Choose between picking a local image (encoded as a data URI) or
  /// entering a URL. The data URI path keeps everything inside `project.json`
  /// so the asset survives ZIP export without separate file management.
  Future<void> _pickImageOrUrl(BuildContext context, EditorProvider ed,
      ElementNode element, String key) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: Text(l10n.propImageUrl),
        children: [
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('upload'),
            child: const Row(children: [
              Icon(Icons.upload_outlined, size: 18),
              SizedBox(width: 8),
              Text('Upload from device'),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop('url'),
            child: const Row(children: [
              Icon(Icons.link, size: 18),
              SizedBox(width: 8),
              Text('Use a URL'),
            ]),
          ),
          if ((element.props[key] ?? '').isNotEmpty)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop('clear'),
              child: const Row(children: [
                Icon(Icons.delete_outline, size: 18),
                SizedBox(width: 8),
                Text('Clear'),
              ]),
            ),
        ],
      ),
    );
    if (choice == null) return;
    if (choice == 'clear') {
      ed.updateProp(element.id, key, '');
      return;
    }
    if (choice == 'url') {
      if (!context.mounted) return;
      await _editTextDialog(
        context,
        title: l10n.propImageUrl,
        initial: element.props[key] ?? '',
        hint: 'https://...',
        onSubmit: (v) => ed.updateProp(element.id, key, v),
      );
      return;
    }
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 2400,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final mime = switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'svg' => 'image/svg+xml',
      _ => 'image/jpeg',
    };
    final dataUri = 'data:$mime;base64,${base64Encode(bytes)}';
    ed.updateProp(element.id, key, dataUri);
  }

  Future<void> _editColorDialog(
    BuildContext context, {
    required String title,
    required String initial,
    required ValueChanged<String> onSubmit,
  }) async {
    final controller = TextEditingController(text: initial);
    final l10n = AppLocalizations.of(context)!;
    const swatches = <String>[
      '#ffffff',
      '#f3f4f6',
      '#e5e7eb',
      '#111827',
      '#1f2937',
      '#374151',
      '#2563eb',
      '#4f46e5',
      '#7c3aed',
      '#db2777',
      '#dc2626',
      '#ea580c',
      '#d97706',
      '#16a34a',
      '#0891b2',
    ];
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(l10n.editProperty(title)),
          content: SizedBox(
            width: 320,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in swatches)
                      _SwatchTile(
                        color: _parseColor(s) ?? Colors.white,
                        selected: controller.text.toLowerCase() == s,
                        onTap: () {
                          controller.text = s;
                          Navigator.of(ctx).pop(s);
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Custom (hex / rgb / name)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(null),
              child: Text(l10n.cancel),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(''),
              child: Text(l10n.clear),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Text(l10n.apply),
            ),
          ],
        );
      },
    );
    if (result != null) onSubmit(result);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.element, required this.ed});
  final ElementNode element;
  final EditorProvider ed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isRoot = element.id == ed.activePage.root.id;
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 6, 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              element.type.id,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.properties,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          const Spacer(),
          IconButton(
            tooltip: l10n.duplicate,
            visualDensity: VisualDensity.compact,
            onPressed: isRoot ? null : () => ed.duplicateElement(element.id),
            icon: const Icon(Icons.content_copy_rounded, size: 18),
          ),
          IconButton(
            tooltip: l10n.moveUp,
            visualDensity: VisualDensity.compact,
            onPressed: isRoot ? null : () => ed.moveElementUp(element.id),
            icon: const Icon(Icons.arrow_upward_rounded, size: 18),
          ),
          IconButton(
            tooltip: l10n.moveDown,
            visualDensity: VisualDensity.compact,
            onPressed: isRoot ? null : () => ed.moveElementDown(element.id),
            icon: const Icon(Icons.arrow_downward_rounded, size: 18),
          ),
          IconButton(
            tooltip: l10n.delete,
            visualDensity: VisualDensity.compact,
            onPressed: isRoot ? null : () => ed.deleteElement(element.id),
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _ChipsRow extends StatelessWidget {
  const _ChipsRow({required this.chips, required this.emptyText});
  final List<_PropChip> chips;
  final String emptyText;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    if (chips.isEmpty) {
      return Center(
        child: Text(
          emptyText,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: chips.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) => chips[i],
    );
  }
}

class _LogicTab extends StatelessWidget {
  const _LogicTab({required this.element, required this.ed});
  final ElementNode element;
  final EditorProvider ed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final events = element.type.supportedEvents;
    if (events.isEmpty) {
      return Center(
        child: Text(
          l10n.noEvents,
          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
        ),
      );
    }
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: events.length,
      separatorBuilder: (_, __) => const SizedBox(width: 8),
      itemBuilder: (_, i) {
        final event = events[i];
        final wsId = WorkspaceIds.forElement(element.id, event);
        final ws = ed.project.workspaces[wsId];
        final configured = ws != null && !ws.isEmpty;
        return _EventChip(
          event: event,
          configured: configured,
          onTap: () => _openWorkshop(context, event),
        );
      },
    );
  }

  Future<void> _openWorkshop(BuildContext context, String event) async {
    final wsId = WorkspaceIds.forElement(element.id, event);
    final existing = ed.project.workspaces[wsId];
    final ws = existing ?? _seedWorkspace(wsId, event);
    ed.project.workspaces[wsId] = ws;

    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BlockWorkshopScreen(initial: ws)),
    );

    // Prune empty hat-only workspaces and notify the host editor so it
    // can re-render the chip indicator + persist.
    if (ws.isEmpty || _onlyEmptyHat(ws)) {
      ed.project.workspaces.remove(wsId);
    }
    ed.markBlocksChanged();
  }

  static BlockWorkspace _seedWorkspace(String id, String event) {
    final hatId = _hatIdFor(event);
    final ws = BlockWorkspace(id: id);
    final hatSpec = BlockRegistry.instance.lookup(hatId);
    if (hatSpec != null) {
      ws.roots.add(BlockNode(specId: hatId));
    }
    return ws;
  }

  static String _hatIdFor(String event) {
    switch (event) {
      case 'onChange':
      // Input-style events behave like change-on-keystroke; map them onto the
      // closest existing hat until dedicated hats are registered.
      case 'onInput':
      case 'onFocus':
      case 'onBlur':
        return 'on_change';
      case 'onSubmit':
        return 'on_submit';
      case 'onLoad':
        return 'on_page_load';
      case 'onClick':
      // Mouse hover events are bound via the click-style hat for now.
      case 'onMouseEnter':
      case 'onMouseLeave':
      default:
        return 'on_click';
    }
  }

  static bool _onlyEmptyHat(BlockWorkspace ws) {
    if (ws.roots.length != 1) return false;
    final root = ws.roots.first;
    final spec = BlockRegistry.instance.lookup(root.specId);
    if (spec == null || spec.shape != BlockShape.hat) return false;
    return root.next == null && ws.variables.isEmpty && ws.functions.isEmpty;
  }
}

class _EventChip extends StatelessWidget {
  const _EventChip({
    required this.event,
    required this.configured,
    required this.onTap,
  });

  final String event;
  final bool configured;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final color = configured ? cs.primary : cs.outline;
    return Material(
      color: configured
          ? cs.primary.withOpacity(0.10)
          : cs.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 132,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color, width: configured ? 1.6 : 1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    configured ? Icons.bolt : Icons.bolt_outlined,
                    color: color,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    event,
                    style: TextStyle(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                configured ? l10n.eventConfigured : l10n.eventEmpty,
                style: TextStyle(color: cs.onSurfaceVariant, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PropChip extends StatelessWidget {
  const _PropChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.swatchColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final Color? swatchColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final hasValue = value.trim().isNotEmpty;
    return SizedBox(
      width: 116,
      child: Material(
        color: cs.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: hasValue
                ? cs.primary.withOpacity(0.45)
                : cs.outlineVariant.withOpacity(0.7),
            width: hasValue ? 1.2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    if (swatchColor != null)
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: swatchColor,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: cs.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                      )
                    else
                      Icon(icon, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  hasValue ? value : '—',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: hasValue ? cs.onSurface : cs.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SwatchTile extends StatelessWidget {
  const _SwatchTile({
    required this.color,
    required this.selected,
    required this.onTap,
  });
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
      ),
    );
  }
}

Color? _parseColor(String? s) {
  if (s == null) return null;
  final t = s.trim().toLowerCase();
  if (t.isEmpty) return null;
  if (t.startsWith('#')) {
    final hex = t.substring(1);
    if (hex.length == 6) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(0xFF000000 | v);
    }
    if (hex.length == 8) {
      final v = int.tryParse(hex, radix: 16);
      if (v != null) return Color(v);
    }
    if (hex.length == 3) {
      final r = int.parse(hex[0] * 2, radix: 16);
      final g = int.parse(hex[1] * 2, radix: 16);
      final b = int.parse(hex[2] * 2, radix: 16);
      return Color.fromARGB(255, r, g, b);
    }
  }
  return null;
}
