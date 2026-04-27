import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';
import 'package:webcraft/services/import_service.dart';

void main() {
  test('importFromZipBytes round-trips a project from project.webcraft.json',
      () {
    final original = Project(
      name: 'Demo',
      pages: [
        PageNode(
          name: 'Home',
          fileName: 'index.html',
          title: 'Home',
          root: ElementNode.defaults(ElementType.container),
        ),
      ],
    );
    final archive = Archive();
    archive.addFile(ArchiveFile.string(
      'public/project.webcraft.json',
      jsonEncode(original.toJson()),
    ));
    final bytes = ZipEncoder().encode(archive)!;
    final imported = ImportService.importFromZipBytes(bytes);
    expect(imported.name, 'Demo');
    expect(imported.pages, hasLength(1));
    expect(imported.pages.first.fileName, 'index.html');
  });

  test('importFromZipBytes throws when manifest is missing', () {
    final archive = Archive()
      ..addFile(ArchiveFile.string('readme.txt', 'nope'));
    final bytes = ZipEncoder().encode(archive)!;
    expect(
      () => ImportService.importFromZipBytes(bytes),
      throwsA(isA<FormatException>()),
    );
  });
}
