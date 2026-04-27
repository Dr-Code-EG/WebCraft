import 'package:uuid/uuid.dart';

import '../blocks/model/block_workspace.dart';
import 'component_spec.dart';
import 'element_node.dart';
import 'page_node.dart';

const _uuid = Uuid();

/// Default CSS custom properties seeded for every new project. Used by the
/// theme editor as the editable palette and emitted as `:root { --... }`
/// declarations in the generated stylesheet.
const Map<String, String> kDefaultThemeVars = {
  '--primary': '#2563eb',
  '--primary-fg': '#ffffff',
  '--accent': '#7c3aed',
  '--bg': '#ffffff',
  '--surface': '#f9fafb',
  '--text': '#111827',
  '--muted': '#6b7280',
  '--border': '#e5e7eb',
  '--radius': '8px',
  '--font-base': '16px',
};

/// Top-level project model. Persisted as a single JSON file per project.
class Project {
  Project({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<PageNode>? pages,
    String? activePageId,
    Map<String, BlockWorkspace>? workspaces,
    Map<String, String>? themeVars,
    String? customCss,
    List<ComponentSpec>? components,
  })  : id = id ?? _uuid.v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        pages = pages ??
            [
              PageNode(
                name: 'Home',
                fileName: 'index.html',
                title: name,
                root: ElementNode.defaults(ElementType.container),
              )
            ],
        workspaces = workspaces ?? <String, BlockWorkspace>{},
        themeVars = themeVars ?? Map<String, String>.from(kDefaultThemeVars),
        customCss = customCss ?? '',
        components = components ?? <ComponentSpec>[] {
    this.activePageId = activePageId ?? this.pages.first.id;
  }

  final String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  final List<PageNode> pages;
  late String activePageId;

  /// Block-editor workspaces keyed by [WorkspaceIds.forPage] /
  /// [WorkspaceIds.forElement]. Empty workspaces are pruned on save.
  final Map<String, BlockWorkspace> workspaces;

  /// Editable CSS custom properties, emitted as `:root { --name: value }`
  /// in the generated stylesheet. Authored from the in-app theme editor.
  final Map<String, String> themeVars;

  /// Free-form CSS appended verbatim after the base stylesheet (and theme
  /// variables). Authored from the in-app custom CSS editor.
  String customCss;

  /// User-saved reusable components — element subtrees that appear in the
  /// element library so they can be cloned into any page.
  final List<ComponentSpec> components;

  PageNode get activePage =>
      pages.firstWhere((p) => p.id == activePageId, orElse: () => pages.first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'activePageId': activePageId,
        'pages': pages.map((p) => p.toJson()).toList(),
        'workspaces': {
          for (final e in workspaces.entries)
            if (!e.value.isEmpty) e.key: e.value.toJson(),
        },
        'themeVars': themeVars,
        'customCss': customCss,
        'components': components.map((c) => c.toJson()).toList(),
      };

  /// Replace the mutable state of [this] with the values from [json] in
  /// place. Identity-preserving — used by the undo/redo system so the
  /// `EditorProvider` can keep its `final Project project` reference.
  void restoreFromJson(Map<String, dynamic> json) {
    final restored = Project.fromJson(json);
    name = restored.name;
    createdAt = restored.createdAt;
    updatedAt = restored.updatedAt;
    pages
      ..clear()
      ..addAll(restored.pages);
    activePageId = restored.activePageId;
    workspaces
      ..clear()
      ..addAll(restored.workspaces);
    themeVars
      ..clear()
      ..addAll(restored.themeVars);
    customCss = restored.customCss;
    components
      ..clear()
      ..addAll(restored.components);
  }

  factory Project.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List?)
            ?.map((p) => PageNode.fromJson(p as Map<String, dynamic>))
            .toList() ??
        <PageNode>[];
    final workspaces = <String, BlockWorkspace>{};
    final ws = json['workspaces'] as Map?;
    if (ws != null) {
      ws.forEach((k, v) {
        workspaces[k as String] =
            BlockWorkspace.fromJson(v as Map<String, dynamic>);
      });
    }
    final themeVars = <String, String>{};
    final tv = json['themeVars'] as Map?;
    if (tv != null) {
      tv.forEach((k, v) {
        themeVars[k as String] = v?.toString() ?? '';
      });
    }
    final components = (json['components'] as List?)
            ?.map((c) => ComponentSpec.fromJson(c as Map<String, dynamic>))
            .toList() ??
        <ComponentSpec>[];
    return Project(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Untitled',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      pages: pages.isEmpty ? null : pages,
      activePageId: json['activePageId'] as String?,
      workspaces: workspaces,
      themeVars: themeVars.isEmpty ? null : themeVars,
      customCss: json['customCss'] as String?,
      components: components,
    );
  }
}
