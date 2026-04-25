import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'screens/projects_screen.dart';
import 'services/project_storage.dart';
import 'state/projects_provider.dart';
import 'state/settings_provider.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = SettingsProvider();
  await settings.load();

  runApp(WebCraftApp(settings: settings));
}

class WebCraftApp extends StatelessWidget {
  const WebCraftApp({super.key, required this.settings});

  final SettingsProvider settings;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settings),
        ChangeNotifierProvider(
          create: (_) => ProjectsProvider(ProjectStorage())..refresh(),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, s, _) {
          return MaterialApp(
            title: 'WebCraft',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: s.themeMode,
            locale: s.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const ProjectsScreen(),
          );
        },
      ),
    );
  }
}
