import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/project.dart';

/// File-system backed persistence for projects.
///
/// Each project is stored as `projects/<id>.json` under the app's documents
/// directory.
class ProjectStorage {
  static const _dirName = 'projects';

  Future<Directory> _projectsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/$_dirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<List<Project>> listProjects() async {
    final dir = await _projectsDir();
    final files = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.json'))
        .cast<File>()
        .toList();

    final projects = <Project>[];
    for (final f in files) {
      try {
        final content = await f.readAsString();
        final json = jsonDecode(content) as Map<String, dynamic>;
        projects.add(Project.fromJson(json));
      } catch (_) {
        // Skip corrupt files.
      }
    }
    projects.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return projects;
  }

  Future<void> saveProject(Project project) async {
    project.updatedAt = DateTime.now();
    final dir = await _projectsDir();
    final file = File('${dir.path}/${project.id}.json');
    await file.writeAsString(jsonEncode(project.toJson()));
  }

  Future<void> deleteProject(String id) async {
    final dir = await _projectsDir();
    final file = File('${dir.path}/$id.json');
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<Project?> loadProject(String id) async {
    final dir = await _projectsDir();
    final file = File('${dir.path}/$id.json');
    if (!await file.exists()) return null;
    final content = await file.readAsString();
    return Project.fromJson(jsonDecode(content) as Map<String, dynamic>);
  }
}
