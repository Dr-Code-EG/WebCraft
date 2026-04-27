import 'package:flutter/foundation.dart';

import '../models/project.dart';
import '../services/project_storage.dart';

/// Owns the list of projects displayed in the project picker.
class ProjectsProvider extends ChangeNotifier {
  ProjectsProvider(this._storage);

  final ProjectStorage _storage;
  List<Project> _projects = [];
  bool _loading = false;

  List<Project> get projects => List.unmodifiable(_projects);
  bool get loading => _loading;

  Future<void> refresh() async {
    _loading = true;
    notifyListeners();
    _projects = await _storage.listProjects();
    _loading = false;
    notifyListeners();
  }

  Future<Project> create(String name) async {
    final p = Project(name: name);
    await _storage.saveProject(p);
    _projects.insert(0, p);
    notifyListeners();
    return p;
  }

  /// Create a new project and seed it with the given template before saving.
  /// Used by the "New from template" picker on the projects screen.
  Future<Project> createWithSeed(
    String name,
    void Function(Project project) seed,
  ) async {
    final p = Project(name: name);
    seed(p);
    await _storage.saveProject(p);
    _projects.insert(0, p);
    notifyListeners();
    return p;
  }

  /// Persist an externally-built project (e.g. one produced by
  /// [ImportService]) and surface it in the list. Renames if the id clashes.
  Future<Project> addImported(Project p) async {
    if (_projects.any((e) => e.id == p.id)) {
      // Avoid id collision by giving the imported copy a fresh id.
      final fresh = Project.fromJson(p.toJson()..['id'] = _newId());
      await _storage.saveProject(fresh);
      _projects.insert(0, fresh);
      notifyListeners();
      return fresh;
    }
    await _storage.saveProject(p);
    _projects.insert(0, p);
    notifyListeners();
    return p;
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);

  Future<void> delete(Project p) async {
    await _storage.deleteProject(p.id);
    _projects.removeWhere((e) => e.id == p.id);
    notifyListeners();
  }

  Future<void> rename(Project p, String newName) async {
    p.name = newName;
    await _storage.saveProject(p);
    notifyListeners();
  }

  Future<void> save(Project p) async {
    await _storage.saveProject(p);
    final idx = _projects.indexWhere((e) => e.id == p.id);
    if (idx >= 0) {
      _projects[idx] = p;
    }
    _projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    notifyListeners();
  }
}
