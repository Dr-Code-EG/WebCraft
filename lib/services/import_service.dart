import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';

import '../models/project.dart';

/// Reads back projects previously written by [ExportService] (a ZIP that
/// contains `project.webcraft.json`) or a raw `.webcraft.json` file.
class ImportService {
  /// Build a [Project] from the file at [path]. Throws [FormatException]
  /// when the file is not a recognised WebCraft archive.
  static Future<Project> importFromPath(String path) async {
    final lower = path.toLowerCase();
    if (lower.endsWith('.json')) {
      final text = await File(path).readAsString();
      return _projectFromJson(text);
    }
    if (lower.endsWith('.zip') || lower.endsWith('.webcraft')) {
      final bytes = await File(path).readAsBytes();
      return importFromZipBytes(bytes);
    }
    throw const FormatException('Unsupported file type');
  }

  /// Decode a WebCraft ZIP from raw bytes (used by tests).
  static Project importFromZipBytes(List<int> bytes) {
    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? jsonFile;
    for (final f in archive) {
      if (f.isFile && f.name.endsWith('project.webcraft.json')) {
        jsonFile = f;
        break;
      }
    }
    if (jsonFile == null) {
      throw const FormatException('project.webcraft.json not found in ZIP');
    }
    final content = utf8.decode(jsonFile.content as List<int>);
    return _projectFromJson(content);
  }

  static Project _projectFromJson(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Project JSON must be an object');
    }
    return Project.fromJson(decoded);
  }
}
