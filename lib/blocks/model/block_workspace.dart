import 'block_node.dart';
import 'block_types.dart';

/// User-declared variable inside a workspace. Names are unique within the
/// workspace; the type is currently advisory only.
class VariableDecl {
  VariableDecl({
    required this.name,
    this.type = BlockType.any,
    this.defaultValue = '',
  });

  String name;
  BlockType type;
  String defaultValue;

  Map<String, dynamic> toJson() => {
        'name': name,
        'type': type.id,
        if (defaultValue.isNotEmpty) 'default': defaultValue,
      };

  factory VariableDecl.fromJson(Map<String, dynamic> j) => VariableDecl(
        name: j['name'] as String,
        type: BlockType.parse(j['type'] as String?),
        defaultValue: j['default'] as String? ?? '',
      );
}

/// User-declared procedure (subroutine) inside a workspace.
class FunctionDecl {
  FunctionDecl({
    required this.name,
    this.params = const [],
    this.returnType = BlockType.voidT,
    List<BlockNode>? body,
  }) : body = body ?? <BlockNode>[];

  String name;
  List<String> params;
  BlockType returnType;
  List<BlockNode> body;

  Map<String, dynamic> toJson() => {
        'name': name,
        'params': params,
        'returnType': returnType.id,
        'body': body.map((n) => n.toJson()).toList(),
      };

  factory FunctionDecl.fromJson(Map<String, dynamic> j) => FunctionDecl(
        name: j['name'] as String,
        params: (j['params'] as List?)?.cast<String>() ?? const [],
        returnType: BlockType.parse(j['returnType'] as String?),
        body: (j['body'] as List?)
                ?.map((e) => BlockNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <BlockNode>[],
      );
}

/// Container for a single block scripting context — typically one event
/// handler on one element, or `onLoad` for a page. Holds free-floating
/// stacks (most common: one Hat-rooted stack) plus shared variables/
/// functions.
class BlockWorkspace {
  BlockWorkspace({
    required this.id,
    List<BlockNode>? roots,
    List<VariableDecl>? variables,
    List<FunctionDecl>? functions,
  })  : roots = roots ?? <BlockNode>[],
        variables = variables ?? <VariableDecl>[],
        functions = functions ?? <FunctionDecl>[];

  /// Stable identifier scoped to a project, e.g. `page:<pageId>:onLoad` or
  /// `el:<elementId>:onClick`.
  final String id;

  final List<BlockNode> roots;
  final List<VariableDecl> variables;
  final List<FunctionDecl> functions;

  bool get isEmpty => roots.isEmpty && variables.isEmpty && functions.isEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'roots': roots.map((n) => n.toJson()).toList(),
        'variables': variables.map((v) => v.toJson()).toList(),
        'functions': functions.map((f) => f.toJson()).toList(),
      };

  factory BlockWorkspace.fromJson(Map<String, dynamic> j) => BlockWorkspace(
        id: j['id'] as String,
        roots: (j['roots'] as List?)
                ?.map((e) => BlockNode.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <BlockNode>[],
        variables: (j['variables'] as List?)
                ?.map((e) => VariableDecl.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <VariableDecl>[],
        functions: (j['functions'] as List?)
                ?.map((e) => FunctionDecl.fromJson(e as Map<String, dynamic>))
                .toList() ??
            <FunctionDecl>[],
      );
}

/// Helpers for composing workspace ids.
abstract final class WorkspaceIds {
  static String forPage(String pageId, {String event = 'onLoad'}) =>
      'page:$pageId:$event';

  static String forElement(String elementId, String event) =>
      'el:$elementId:$event';
}
