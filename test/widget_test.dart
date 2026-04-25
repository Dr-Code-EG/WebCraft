import 'package:flutter_test/flutter_test.dart';

import 'package:webcraft/main.dart';
import 'package:webcraft/state/settings_provider.dart';

void main() {
  testWidgets('App boots and shows the empty state', (tester) async {
    final settings = SettingsProvider();
    await tester.pumpWidget(WebCraftApp(settings: settings));
    await tester.pump(const Duration(milliseconds: 100));

    // Should show our app brand somewhere.
    expect(find.text('WebCraft'), findsWidgets);
  });
}
