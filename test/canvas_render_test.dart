import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:webcraft/models/element_node.dart';
import 'package:webcraft/models/page_node.dart';
import 'package:webcraft/models/project.dart';
import 'package:webcraft/state/editor_provider.dart';
import 'package:webcraft/widgets/editor/canvas_view.dart';

Widget _wrap(EditorProvider ed) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: ChangeNotifierProvider.value(
      value: ed,
      child: const Scaffold(body: SizedBox(height: 800, child: CanvasView())),
    ),
  );
}

void main() {
  testWidgets('Canvas renders newly added heading + button', (tester) async {
    final project = Project(name: 'Test', pages: [
      PageNode(
          name: 'Home',
          fileName: 'index.html',
          root: ElementNode.defaults(ElementType.container)),
    ]);
    final ed = EditorProvider(project);

    await tester.pumpWidget(_wrap(ed));
    await tester.pumpAndSettle();

    // Initially the empty drop placeholder is visible.
    ed.addElement(ElementType.heading);
    await tester.pump();
    expect(find.text('Heading'), findsAtLeast(1));
    expect(tester.takeException(), isNull);

    ed.addElement(ElementType.button);
    await tester.pump();
    expect(find.text('Click me'), findsAtLeast(1));
    expect(tester.takeException(), isNull);

    ed.addElement(ElementType.paragraph);
    await tester.pump();
    expect(find.textContaining('Lorem ipsum'), findsAtLeast(1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Canvas reflects deletion + reorder', (tester) async {
    final project = Project(name: 'Test', pages: [
      PageNode(
          name: 'Home',
          fileName: 'index.html',
          root: ElementNode.defaults(ElementType.container)),
    ]);
    final ed = EditorProvider(project);
    await tester.pumpWidget(_wrap(ed));
    await tester.pumpAndSettle();

    ed.addElement(ElementType.heading);
    ed.addElement(ElementType.paragraph);
    await tester.pump();
    expect(find.text('Heading'), findsAtLeast(1));

    final h = project.activePage.root.children.first.id;
    ed.deleteElement(h);
    await tester.pump();
    expect(find.text('Heading'), findsNothing);
  });
}
