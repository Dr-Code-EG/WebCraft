import 'package:uuid/uuid.dart';

import '../blocks/model/block_workspace.dart';
import 'element_node.dart';
import 'page_node.dart';

const _uuid = Uuid();

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
        workspaces = workspaces ?? <String, BlockWorkspace>{} {
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
    return Project(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Untitled',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      pages: pages.isEmpty ? null : pages,
      activePageId: json['activePageId'] as String?,
      workspaces: workspaces,
    );
  }
}
