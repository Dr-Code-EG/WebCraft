import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../blocks/widgets/block_workshop_screen.dart';
import '../blocks/widgets/blocks_preview_screen.dart';
import '../state/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settings)),
      body: Consumer<SettingsProvider>(
        builder: (context, s, _) {
          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _SectionHeader(title: l10n.language),
              RadioListTile<String>(
                value: 'ar',
                groupValue: s.locale.languageCode,
                onChanged: (v) {
                  if (v != null) s.setLocale(Locale(v));
                },
                title: Text(l10n.arabic),
              ),
              RadioListTile<String>(
                value: 'en',
                groupValue: s.locale.languageCode,
                onChanged: (v) {
                  if (v != null) s.setLocale(Locale(v));
                },
                title: Text(l10n.english),
              ),
              const Divider(),
              _SectionHeader(title: l10n.theme),
              RadioListTile<ThemeMode>(
                value: ThemeMode.system,
                groupValue: s.themeMode,
                onChanged: (v) {
                  if (v != null) s.setThemeMode(v);
                },
                title: Text(l10n.themeSystem),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.light,
                groupValue: s.themeMode,
                onChanged: (v) {
                  if (v != null) s.setThemeMode(v);
                },
                title: Text(l10n.themeLight),
              ),
              RadioListTile<ThemeMode>(
                value: ThemeMode.dark,
                groupValue: s.themeMode,
                onChanged: (v) {
                  if (v != null) s.setThemeMode(v);
                },
                title: Text(l10n.themeDark),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.handyman_outlined),
                title: const Text('Block Workshop'),
                subtitle: const Text(
                    'Drag, snap & edit blocks in a Flutter-native workspace'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const BlockWorkshopScreen(),
                  ));
                },
              ),
              ListTile(
                leading: const Icon(Icons.extension_outlined),
                title: const Text('Blocks Preview (read-only)'),
                subtitle: const Text(
                    'Static gallery of every registered BlockSpec'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => const BlocksPreviewScreen(),
                  ));
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.about),
                subtitle: const Text('WebCraft v0.5.0-beta'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}
