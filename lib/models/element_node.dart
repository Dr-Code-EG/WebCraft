import 'package:uuid/uuid.dart';

const _uuid = Uuid();

/// Type identifiers for HTML-style elements supported in the visual editor.
enum ElementType {
  container,
  row,
  column,
  heading,
  paragraph,
  text,
  button,
  image,
  input,
  textarea,
  form,
  link,
  divider,
  spacer,
  card,
  list,
  video,
}

extension ElementTypeX on ElementType {
  String get id {
    switch (this) {
      case ElementType.container:
        return 'container';
      case ElementType.row:
        return 'row';
      case ElementType.column:
        return 'column';
      case ElementType.heading:
        return 'heading';
      case ElementType.paragraph:
        return 'paragraph';
      case ElementType.text:
        return 'text';
      case ElementType.button:
        return 'button';
      case ElementType.image:
        return 'image';
      case ElementType.input:
        return 'input';
      case ElementType.textarea:
        return 'textarea';
      case ElementType.form:
        return 'form';
      case ElementType.link:
        return 'link';
      case ElementType.divider:
        return 'divider';
      case ElementType.spacer:
        return 'spacer';
      case ElementType.card:
        return 'card';
      case ElementType.list:
        return 'list';
      case ElementType.video:
        return 'video';
    }
  }

  static ElementType fromId(String id) {
    return ElementType.values.firstWhere(
      (e) => e.id == id,
      orElse: () => ElementType.container,
    );
  }

  /// Whether this element can contain children in the editor's tree.
  bool get acceptsChildren {
    switch (this) {
      case ElementType.container:
      case ElementType.row:
      case ElementType.column:
      case ElementType.form:
      case ElementType.card:
      case ElementType.list:
      case ElementType.link:
        return true;
      default:
        return false;
    }
  }
}

/// A node in the page element tree. Holds type, properties, style, and children.
class ElementNode {
  ElementNode({
    String? id,
    required this.type,
    Map<String, String>? props,
    Map<String, String>? style,
    List<ElementNode>? children,
    Map<String, ElementEvent>? events,
  })  : id = id ?? _uuid.v4(),
        props = props ?? <String, String>{},
        style = style ?? <String, String>{},
        children = children ?? <ElementNode>[],
        events = events ?? <String, ElementEvent>{};

  final String id;
  ElementType type;

  /// HTML attributes / content (text, src, href, placeholder, alt, etc).
  final Map<String, String> props;

  /// CSS-like declarations (color, background, padding, font-size, etc).
  final Map<String, String> style;

  final List<ElementNode> children;

  /// Block-event handlers keyed by event name (e.g. `onClick`, `onChange`).
  final Map<String, ElementEvent> events;

  ElementNode copyWithNewIds() {
    return ElementNode(
      type: type,
      props: Map.of(props),
      style: Map.of(style),
      children: children.map((c) => c.copyWithNewIds()).toList(),
      events: events.map((k, v) => MapEntry(k, v.copy())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.id,
        'props': props,
        'style': style,
        'children': children.map((c) => c.toJson()).toList(),
        if (events.isNotEmpty)
          'events': events.map((k, v) => MapEntry(k, v.toJson())),
      };

  factory ElementNode.fromJson(Map<String, dynamic> json) {
    return ElementNode(
      id: json['id'] as String?,
      type: ElementTypeX.fromId(json['type'] as String? ?? 'container'),
      props: (json['props'] as Map?)?.cast<String, String>() ?? {},
      style: (json['style'] as Map?)?.cast<String, String>() ?? {},
      children: (json['children'] as List?)
              ?.map((c) => ElementNode.fromJson(c as Map<String, dynamic>))
              .toList() ??
          [],
      events: (json['events'] as Map?)?.map(
            (k, v) => MapEntry(
                k as String, ElementEvent.fromJson(v as Map<String, dynamic>)),
          ) ??
          {},
    );
  }

  /// Supported event names for this element.
  List<String> get supportedEvents {
    switch (type) {
      case ElementType.button:
      case ElementType.link:
      case ElementType.image:
      case ElementType.card:
      case ElementType.text:
      case ElementType.heading:
      case ElementType.paragraph:
      case ElementType.container:
      case ElementType.row:
      case ElementType.column:
      case ElementType.list:
      case ElementType.divider:
      case ElementType.spacer:
      case ElementType.video:
        return const ['onClick'];
      case ElementType.input:
      case ElementType.textarea:
        return const ['onChange', 'onClick'];
      case ElementType.form:
        return const ['onSubmit'];
    }
  }

  /// Create a default-styled element of [type] with sensible default props.
  factory ElementNode.defaults(ElementType type) {
    final node = ElementNode(type: type);
    switch (type) {
      case ElementType.container:
        node.style.addAll({
          'padding': '16px',
          'background': '#ffffff',
        });
        break;
      case ElementType.row:
        node.style.addAll({
          'display': 'flex',
          'flex-direction': 'row',
          'gap': '12px',
          'padding': '12px',
        });
        break;
      case ElementType.column:
        node.style.addAll({
          'display': 'flex',
          'flex-direction': 'column',
          'gap': '12px',
          'padding': '12px',
        });
        break;
      case ElementType.heading:
        node.props['text'] = 'Heading';
        node.props['level'] = 'h1';
        node.style.addAll({
          'font-size': '32px',
          'font-weight': '700',
          'color': '#111827',
        });
        break;
      case ElementType.paragraph:
        node.props['text'] =
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit.';
        node.style.addAll({
          'font-size': '16px',
          'color': '#374151',
          'line-height': '1.6',
        });
        break;
      case ElementType.text:
        node.props['text'] = 'Text';
        node.style.addAll({
          'font-size': '16px',
          'color': '#111827',
        });
        break;
      case ElementType.button:
        node.props['text'] = 'Click me';
        node.props['type'] = 'button';
        node.style.addAll({
          'background': '#2563eb',
          'color': '#ffffff',
          'padding': '10px 20px',
          'border-radius': '8px',
          'font-size': '16px',
          'font-weight': '600',
          'border': 'none',
          'cursor': 'pointer',
        });
        break;
      case ElementType.image:
        node.props['src'] = 'https://via.placeholder.com/400x200?text=WebCraft';
        node.props['alt'] = 'image';
        node.style.addAll({
          'max-width': '100%',
          'height': 'auto',
          'border-radius': '8px',
        });
        break;
      case ElementType.input:
        node.props['type'] = 'text';
        node.props['placeholder'] = 'Type here...';
        node.style.addAll({
          'padding': '10px 14px',
          'border': '1px solid #d1d5db',
          'border-radius': '8px',
          'font-size': '16px',
          'width': '100%',
          'box-sizing': 'border-box',
        });
        break;
      case ElementType.textarea:
        node.props['placeholder'] = 'Write something...';
        node.props['rows'] = '4';
        node.style.addAll({
          'padding': '10px 14px',
          'border': '1px solid #d1d5db',
          'border-radius': '8px',
          'font-size': '16px',
          'width': '100%',
          'box-sizing': 'border-box',
          'font-family': 'inherit',
        });
        break;
      case ElementType.form:
        node.props['action'] = '#';
        node.props['method'] = 'post';
        node.style.addAll({
          'display': 'flex',
          'flex-direction': 'column',
          'gap': '12px',
          'padding': '16px',
          'background': '#f9fafb',
          'border-radius': '8px',
        });
        break;
      case ElementType.link:
        node.props['text'] = 'Link';
        node.props['href'] = '#';
        node.style.addAll({
          'color': '#2563eb',
          'text-decoration': 'underline',
        });
        break;
      case ElementType.divider:
        node.style.addAll({
          'border-top': '1px solid #e5e7eb',
          'margin': '16px 0',
          'width': '100%',
          'height': '0',
        });
        break;
      case ElementType.spacer:
        node.style.addAll({
          'height': '32px',
          'width': '100%',
        });
        break;
      case ElementType.card:
        node.style.addAll({
          'background': '#ffffff',
          'padding': '16px',
          'border-radius': '12px',
          'box-shadow': '0 1px 3px rgba(0,0,0,0.1)',
          'display': 'flex',
          'flex-direction': 'column',
          'gap': '8px',
        });
        break;
      case ElementType.list:
        node.props['ordered'] = 'false';
        node.style.addAll({
          'padding-left': '20px',
          'color': '#374151',
        });
        break;
      case ElementType.video:
        node.props['src'] = '';
        node.props['controls'] = 'true';
        node.style.addAll({
          'max-width': '100%',
        });
        break;
    }
    return node;
  }
}

/// Saved Blockly workspace XML + last-generated JS body for one event handler.
class ElementEvent {
  ElementEvent({required this.workspaceXml, this.jsBody = ''});

  String workspaceXml;
  String jsBody;

  ElementEvent copy() =>
      ElementEvent(workspaceXml: workspaceXml, jsBody: jsBody);

  Map<String, dynamic> toJson() => {
        'workspaceXml': workspaceXml,
        'jsBody': jsBody,
      };

  factory ElementEvent.fromJson(Map<String, dynamic> json) => ElementEvent(
        workspaceXml: json['workspaceXml'] as String? ?? '',
        jsBody: json['jsBody'] as String? ?? '',
      );

  bool get isEmpty => workspaceXml.trim().isEmpty && jsBody.trim().isEmpty;
}
