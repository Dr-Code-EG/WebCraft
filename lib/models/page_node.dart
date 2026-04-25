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
    Map<String, ElementEvent>? events,
  })  : id = id ?? _uuid.v4(),
        title = title ?? name,
        root = root ?? ElementNode.defaults(ElementType.container),
        events = events ?? <String, ElementEvent>{};

  final String id;
  String name;
  String fileName;
  String title;
  ElementNode root;

  /// Page-scoped block-event handlers (e.g. `onLoad`).
  final Map<String, ElementEvent> events;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'fileName': fileName,
        'title': title,
        'root': root.toJson(),
        if (events.isNotEmpty)
          'events': events.map((k, v) => MapEntry(k, v.toJson())),
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
      events: (json['events'] as Map?)?.map(
            (k, v) => MapEntry(
                k as String, ElementEvent.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
    );
  }
}
