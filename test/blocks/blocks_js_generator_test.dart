import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/blocks/catalog/block_registry.dart';
import 'package:webcraft/blocks/model/block_node.dart';
import 'package:webcraft/blocks/model/block_types.dart';
import 'package:webcraft/blocks/model/block_workspace.dart';
import 'package:webcraft/codegen/blocks_js_generator.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';

BlockNode _node(String specId,
    {Map<String, String>? fields,
    Map<String, BlockNode>? slots,
    Map<String, List<BlockNode>>? mouths,
    BlockNode? next}) {
  return BlockNode(
    specId: specId,
    fieldValues: fields ?? <String, String>{},
    slotChildren: slots ?? <String, BlockNode>{},
    mouthStacks: mouths ?? <String, List<BlockNode>>{},
    next: next,
  );
}

Project _projectWith(BlockWorkspace ws) {
  final page = PageNode(
    name: 'Home',
    fileName: 'index.html',
    title: 'Home',
    root: ElementNode.defaults(ElementType.container),
  );
  return Project(
    name: 'P',
    pages: [page],
    workspaces: {ws.id: ws},
  );
}

void main() {
  setUp(() => BlockRegistry.instance.seedDefaults());

  test('returns empty string when project has no non-empty workspaces', () {
    final p = _projectWith(BlockWorkspace(id: 'page:p1:onLoad'));
    expect(BlocksJsGenerator.generateProject(p), isEmpty);
  });

  test('emits DOMContentLoaded handler for page-scoped onLoad workspaces', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('set_var', fields: {'name': 'count'}, slots: {
              'value': _node('number_literal', fields: {'value': '5'})
            })),
      ],
      variables: [VariableDecl(name: 'count', type: BlockType.number)],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('DOMContentLoaded'));
    expect(js, contains('let count = 0;'));
    expect(js, contains('count = 5;'));
  });

  test('binds element-scoped click workspaces via addEventListener', () {
    final ws = BlockWorkspace(
      id: 'el:btn1:onClick',
      roots: [
        _node('on_click',
            next: _node('dom_set_text', fields: {'target': 'self'}, slots: {
              'value': _node('text_literal', fields: {'value': 'Hello'})
            })),
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('\$("btn1")'));
    expect(js, contains('addEventListener("click"'));
    expect(js, contains('__t.textContent = "Hello"'));
  });

  test('compiles math binop with × replaced by *', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('set_var', fields: {'name': 'r'}, slots: {
              'value': _node('math_binop', fields: {'op': '×'}, slots: {
                'a': _node('number_literal', fields: {'value': '3'}),
                'b': _node('number_literal', fields: {'value': '4'}),
              }),
            })),
      ],
      variables: [VariableDecl(name: 'r', type: BlockType.number)],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('r = (3 * 4);'));
  });

  test('compiles if/else with then and else mouths', () {
    final ws = BlockWorkspace(
      id: 'el:btn1:onClick',
      roots: [
        _node('on_click',
            next: _node('if_else', slots: {
              'cond': _node('compare', fields: {'op': '=='}, slots: {
                'a': _node('get_var', fields: {'name': 'x'}),
                'b': _node('number_literal', fields: {'value': '0'}),
              })
            }, mouths: {
              'then': [_node('dom_show_hide',
                  fields: {'action': 'show', 'target': 'banner'})],
              'else': [_node('dom_show_hide',
                  fields: {'action': 'hide', 'target': 'banner'})],
            }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('if ((x == 0))'));
    expect(js, contains('} else {'));
    expect(js, contains('"banner"'));
    expect(js, contains('style.display = ""'));
    expect(js, contains('style.display = "none"'));
  });

  test('compiles repeat_n into for loop', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('repeat_n', slots: {
              'count': _node('number_literal', fields: {'value': '3'})
            }, mouths: {
              'body': [
                _node('storage_set', fields: {'key': 'k'}, slots: {
                  'value': _node('text_literal', fields: {'value': 'v'})
                })
              ],
            }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('for (var __i = 0, __n = (3)'));
    expect(js, contains('localStorage.setItem("k"'));
  });

  test('compiles dom_set_style with camelCased CSS prop', () {
    final ws = BlockWorkspace(
      id: 'el:box1:onClick',
      roots: [
        _node('on_click',
            next: _node('dom_set_style',
                fields: {'target': 'self', 'prop': 'background-color'},
                slots: {
                  'value': _node('text_literal', fields: {'value': 'red'})
                }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('style["backgroundColor"] = "red"'));
  });

  test('logic_andor maps "or" to "||" and default "and" to "&&"', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('if_else', slots: {
              'cond': _node('logic_andor', fields: {'op': 'or'}, slots: {
                'a': _node('get_var', fields: {'name': 'a'}),
                'b': _node('get_var', fields: {'name': 'b'}),
              })
            }, mouths: {
              'then': [],
            }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('(a || b)'));
  });

  test('safe-names variables with weird characters', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('set_var', fields: {'name': 'my-var!'}, slots: {
              'value': _node('number_literal', fields: {'value': '1'})
            })),
      ],
      variables: [VariableDecl(name: 'my-var!', type: BlockType.number)],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('let my_var_'));
    expect(js, contains('my_var_ = 1;'));
  });

  test('escapes special characters in text literals', () {
    final ws = BlockWorkspace(
      id: 'el:b:onClick',
      roots: [
        _node('on_click',
            next: _node('dom_set_text', fields: {'target': 'self'}, slots: {
              'value': _node('text_literal',
                  fields: {'value': 'He said "hi"\nthen'})
            }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains(r'"He said \"hi\"\nthen"'));
  });

  test('list_add pushes onto the list slot expression', () {
    final ws = BlockWorkspace(
      id: 'page:p1:onLoad',
      roots: [
        _node('on_page_load',
            next: _node('list_add', slots: {
              'list': _node('get_var', fields: {'name': 'items'}),
              'item': _node('text_literal', fields: {'value': 'x'}),
            }))
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, contains('__l.push("x")'));
  });

  test('escapes </script> sequences inside string literals', () {
    final ws = BlockWorkspace(
      id: 'el:btn1:onClick',
      roots: [
        _node('on_click',
            next: _node('dom_set_text', fields: {
              'target': 'self'
            }, slots: {
              'value':
                  _node('text_literal', fields: {'value': '</script>oops'})
            })),
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, isNot(contains('</script>')));
    expect(js, contains(r'<\/script>'));
  });

  test('dom_get_value caches the target lookup once', () {
    final ws = BlockWorkspace(
      id: 'el:btn1:onClick',
      roots: [
        _node('on_click',
            next: _node('set_var', fields: {'name': 'v'}, slots: {
              'value': _node('dom_get_value', fields: {'target': 'inputA'})
            })),
      ],
      variables: [VariableDecl(name: 'v', type: BlockType.text)],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    // Should query the DOM once via a temp var, not repeat `$("inputA")`.
    expect(js, contains('var __g ='));
    final occurrences = '\$("inputA")'.allMatches(js).length;
    expect(occurrences, 1);
  });

  test('skips workspaces without a hat-shaped root', () {
    final ws = BlockWorkspace(
      id: 'el:btn1:onClick',
      roots: [
        _node('set_var', fields: {'name': 'x'}, slots: {
          'value': _node('number_literal', fields: {'value': '1'})
        })
      ],
    );
    final js = BlocksJsGenerator.generateProject(_projectWith(ws));
    expect(js, isEmpty);
  });
}
