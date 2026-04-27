import 'package:uuid/uuid.dart';

import 'element_node.dart';

const _uuid = Uuid();

/// A reusable element subtree saved by the user. Components are stored on the
/// project so they can be inserted into any page from the element library.
///
/// Components currently capture only the visual element tree — block
/// workspaces are not bundled, since copying them would create cross-element
/// id collisions on insertion.
class ComponentSpec {
  ComponentSpec({
    String? id,
    required this.name,
    required this.root,
    String? icon,
  })  : id = id ?? _uuid.v4(),
        icon = icon ?? 'widgets';

  final String id;
  String name;
  String icon;
  ElementNode root;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'icon': icon,
        'root': root.toJson(),
      };

  factory ComponentSpec.fromJson(Map<String, dynamic> json) {
    return ComponentSpec(
      id: json['id'] as String?,
      name: json['name'] as String? ?? 'Component',
      icon: json['icon'] as String?,
      root: ElementNode.fromJson(json['root'] as Map<String, dynamic>),
    );
  }
}
