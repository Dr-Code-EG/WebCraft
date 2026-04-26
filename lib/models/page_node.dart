import 'package:uuid/uuid.dart';

import 'element_node.dart';

const _uuid = Uuid();

/// Represents a single page in a project.
class PageNode {
  PageNode({
    String? id,
    required this.name,
    required this.fileName,
    ElementNode? root,
    String? title,
  })  : id = id ?? _uuid.v4(),
        title = title ?? name,
        root = root ?? ElementNode.defaults(ElementType.container);

  final String id;
  String name;
  String fileName;
  String title;
  ElementNode root;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
        'title': title,
        'root': root.toJson(),
      };

  factory PageNode.fromJson(Map<String, dynamic> json) {
    return PageNode(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Page',
      fileName: json['fileName'] as String? ?? 'index.html',
      title: json['title'] as String?,
      root: json['root'] != null
          ? ElementNode.fromJson(json['root'] as Map<String, dynamic>)
          : null,
    );
  }
}
