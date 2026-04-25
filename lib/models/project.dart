import 'package:uuid/uuid.dart';

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
            ] {
    this.activePageId = activePageId ?? this.pages.first.id;
  }

  final String id;
  String name;
  DateTime createdAt;
  DateTime updatedAt;
  final List<PageNode> pages;
  late String activePageId;

  PageNode get activePage =>
      pages.firstWhere((p) => p.id == activePageId, orElse: () => pages.first);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'activePageId': activePageId,
        'pages': pages.map((p) => p.toJson()).toList(),
      };

  factory Project.fromJson(Map<String, dynamic> json) {
    final pages = (json['pages'] as List?)
            ?.map((p) => PageNode.fromJson(p as Map<String, dynamic>))
            .toList() ??
        <PageNode>[];
    return Project(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Untitled',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
      pages: pages.isEmpty ? null : pages,
      activePageId: json['activePageId'] as String?,
    );
  }
}
