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
