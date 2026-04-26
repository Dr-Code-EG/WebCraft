import 'package:flutter/foundation.dart';

import '../models/element_node.dart';
import '../models/page_node.dart';
import '../models/project.dart';

/// Drives the visual editor: selection, mutations, undo/redo (basic).
class EditorProvider extends ChangeNotifier {
  EditorProvider(this.project);

  final Project project;
  String? _selectedElementId;
  bool _dirty = false;

  String? get selectedElementId => _selectedElementId;
  bool get dirty => _dirty;

  PageNode get activePage => project.activePage;

  ElementNode? get selectedElement {
    if (_selectedElementId == null) return null;
    return _findById(activePage.root, _selectedElementId!);
  }

  void select(String? id) {
    _selectedElementId = id;
    notifyListeners();
  }

  void selectPage(String pageId) {
    project.activePageId = pageId;
    _selectedElementId = null;
    _markDirty();
  }

  void addPage(String name) {
    final fileName = '${_slug(name)}.html';
    final page = PageNode(
      name: name,
      fileName: fileName,
      root: ElementNode.defaults(ElementType.container),
    );
    project.pages.add(page);
    project.activePageId = page.id;
    _markDirty();
  }

  void deletePage(String pageId) {
    if (project.pages.length <= 1) return;
    project.pages.removeWhere((p) => p.id == pageId);
    project.activePageId = project.pages.first.id;
    _markDirty();
  }

  /// Add a new element to the currently selected container, or to root.
  void addElement(ElementType type) {
    final node = ElementNode.defaults(type);
    final parent = _resolveDropParent();
    parent.children.add(node);
    _selectedElementId = node.id;
    _markDirty();
  }

  /// Add [type] as a child of element [parentId] (must accept children).
  void addElementInside(ElementType type, String parentId) {
    final parent = _findById(activePage.root, parentId);
    if (parent == null || !parent.type.acceptsChildren) return;
    final node = ElementNode.defaults(type);
    parent.children.add(node);
    _selectedElementId = node.id;
    _markDirty();
  }

  void deleteElement(String id) {
    if (id == activePage.root.id) return;
    _removeById(activePage.root, id);
    if (_selectedElementId == id) _selectedElementId = null;
    _markDirty();
  }

  void duplicateElement(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null) return;
    final clone = found.parent.children[found.index].copyWithNewIds();
    found.parent.children.insert(found.index + 1, clone);
    _selectedElementId = clone.id;
    _markDirty();
  }

  void moveElementUp(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null || found.index == 0) return;
    final list = found.parent.children;
    final node = list.removeAt(found.index);
    list.insert(found.index - 1, node);
    _markDirty();
  }

  void moveElementDown(String id) {
    final found = _findParentAndIndex(activePage.root, id);
    if (found == null) return;
    final list = found.parent.children;
    if (found.index >= list.length - 1) return;
    final node = list.removeAt(found.index);
    list.insert(found.index + 1, node);
    _markDirty();
  }

  void updateProp(String elementId, String key, String value) {
    final el = _findById(activePage.root, elementId);
    if (el == null) return;
    if (value.isEmpty) {
      el.props.remove(key);
    } else {
      el.props[key] = value;
    }
    _markDirty();
  }

  void updateStyle(String elementId, String key, String value) {
    final el = _findById(activePage.root, elementId);
    if (el == null) return;
    if (value.isEmpty) {
      el.style.remove(key);
    } else {
      el.style[key] = value;
    }
    _markDirty();
  }

  void markSaved() {
    _dirty = false;
    notifyListeners();
  }

  /// Notify listeners that block workspaces (event handlers, variables) on
  /// the project changed externally — e.g. after returning from the Block
  /// Workshop screen. Forces a re-paint of Logic-tab chips and persistence.
  void markBlocksChanged() {
    _markDirty();
  }

  void _markDirty() {
    _dirty = true;
    notifyListeners();
  }

  ElementNode _resolveDropParent() {
    if (_selectedElementId != null) {
      final el = _findById(activePage.root, _selectedElementId!);
      if (el != null && el.type.acceptsChildren) return el;
    }
    return activePage.root;
  }

  ElementNode? _findById(ElementNode root, String id) {
    if (root.id == id) return root;
    for (final c in root.children) {
      final r = _findById(c, id);
      if (r != null) return r;
    }
    return null;
  }

  bool _removeById(ElementNode root, String id) {
    for (var i = 0; i < root.children.length; i++) {
      if (root.children[i].id == id) {
        root.children.removeAt(i);
        return true;
      }
      if (_removeById(root.children[i], id)) return true;
    }
    return false;
  }

  _ParentIndex? _findParentAndIndex(ElementNode root, String id) {
    for (var i = 0; i < root.children.length; i++) {
      if (root.children[i].id == id) {
        return _ParentIndex(root, i);
      }
      final inner = _findParentAndIndex(root.children[i], id);
      if (inner != null) return inner;
    }
    return null;
  }

  static String _slug(String name) {
    final lower = name.trim().toLowerCase();
    final s = lower.replaceAll(RegExp(r'[^a-z0-9_-]+'), '-');
    final trimmed = s.replaceAll(RegExp(r'(^-+|-+$)'), '');
    return trimmed.isEmpty ? 'page' : trimmed;
  }
}

class _ParentIndex {
  _ParentIndex(this.parent, this.index);
  final ElementNode parent;
  final int index;
}
