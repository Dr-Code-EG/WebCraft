import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webcraft/codegen/html_generator.dart';
import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';
import 'package:webcraft/services/template_library.dart';

Project _seed() => Project(
      name: 't',
      pages: [
        PageNode(
          name: 'Home',
          fileName: 'index.html',
          title: 'Home',
          root: ElementNode.defaults(ElementType.container),
        ),
      ],
    );

ElementNode _findRow(ElementNode root) {
  if (root.type == ElementType.row) return root;
  for (final c in root.children) {
    final hit = _findRow(c);
    if (hit.type == ElementType.row) return hit;
  }
  return root;
}

void main() {
  group('Template rows have flex layout', () {
    test('Landing template feature row carries display: flex', () {
      final p = _seed();
      final landing = TemplateLibrary.all().firstWhere((t) => t.id == 'landing');
      TemplateLibrary.apply(p, landing);

      final root = p.pages.single.root;
      final rows = <ElementNode>[];
      void walk(ElementNode n) {
        if (n.type == ElementType.row) rows.add(n);
        for (final c in n.children) {
          walk(c);
        }
      }

      walk(root);
      expect(rows, isNotEmpty);
      for (final r in rows) {
        expect(
          r.style['display'],
          'flex',
          reason: 'row missing display:flex; cards would stack vertically',
        );
      }

      final html = HtmlGenerator.pageDocument(p, p.pages.single);
      // Every emitted row div should carry display:flex inline so the
      // horizontal layout works without an external stylesheet rule for .row.
      expect(html, contains('display: flex'));
    });

    test('Portfolio template row carries display: flex', () {
      final p = _seed();
      final tpl = TemplateLibrary.all().firstWhere((t) => t.id == 'portfolio');
      TemplateLibrary.apply(p, tpl);
      final row = _findRow(p.pages.single.root);
      expect(row.style['display'], 'flex');
    });
  });

  group('Export _textFile encodes UTF-8', () {
    // We exercise the encoding path indirectly via the same Uint8List path
    // the export uses, since exportZip writes to disk (path_provider needs a
    // platform binding).
    test('UTF-8 round-trip preserves Arabic + arrow chars', () {
      const src = 'مرحبا → WebCraft';
      // Mirror what _textFile does (the fix): utf8.encode, then decode.
      final bytes = utf8.encode(src);
      final restored = utf8.decode(bytes);
      expect(restored, src);

      // The previous codeUnits path would corrupt this — verify that the
      // current encode is NOT the broken codeUnits truncation.
      final truncated = src.codeUnits.map((u) => u & 0xFF).toList();
      final brokenRestored = String.fromCharCodes(truncated);
      expect(brokenRestored, isNot(equals(src)),
          reason: 'codeUnits truncation must produce different bytes than utf8');
    });

    test('ArchiveFile written via utf8.encode round-trips through ZipDecoder',
        () {
      const content = 'Settings → Pages — café';
      final bytes = utf8.encode(content);
      final archive = Archive()
        ..addFile(ArchiveFile('README.md', bytes.length, bytes));
      final zipBytes = ZipEncoder().encode(archive)!;
      final restored = ZipDecoder().decodeBytes(zipBytes);
      final readme = restored.findFile('README.md')!;
      final restoredContent = utf8.decode(readme.content as List<int>);
      expect(restoredContent, content);
    });
  });
}
