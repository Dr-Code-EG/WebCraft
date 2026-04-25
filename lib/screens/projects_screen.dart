import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../models/project.dart';
import '../state/projects_provider.dart';
import 'editor_screen.dart';
import 'settings_screen.dart';

class ProjectsScreen extends StatelessWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.appName,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            tooltip: l10n.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Consumer<ProjectsProvider>(
        builder: (context, prov, _) {
          if (prov.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (prov.projects.isEmpty) {
            return _EmptyState(
              onCreate: () => _showCreateDialog(context),
            );
          }
          return RefreshIndicator(
            onRefresh: prov.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: prov.projects.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final p = prov.projects[i];
                return _ProjectTile(project: p);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDialog(context),
        icon: const Icon(Icons.add),
        label: Text(l10n.newProject),
      ),
    );
  }

  void _showCreateDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.createProject),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            labelText: l10n.projectName,
            hintText: l10n.projectNameHint,
          ),
          onSubmitted: (_) => _confirmCreate(ctx, context, controller.text),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => _confirmCreate(ctx, context, controller.text),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmCreate(
      BuildContext dialogCtx, BuildContext rootCtx, String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final prov = Provider.of<ProjectsProvider>(rootCtx, listen: false);
    final project = await prov.create(trimmed);
    if (!dialogCtx.mounted) return;
    Navigator.of(dialogCtx).pop();
    if (!rootCtx.mounted) return;
    Navigator.of(rootCtx).push(
      MaterialPageRoute(builder: (_) => EditorScreen(project: project)),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [cs.primary, cs.tertiary],
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: cs.primary.withOpacity(0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.public_rounded,
                  size: 56, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.welcomeTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.welcomeSubtitle,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: Text(l10n.getStarted),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProjectTile extends StatelessWidget {
  const _ProjectTile({required this.project});
  final Project project;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final df =
        DateFormat.yMMMd(Localizations.localeOf(context).toString()).add_jm();

    final pageCount = project.pages.length;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                cs.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child:
              const Icon(Icons.public_rounded, color: Colors.white, size: 28),
        ),
        title: Text(
          project.name,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              Icon(Icons.layers_outlined, size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Text('$pageCount',
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant)),
              const SizedBox(width: 12),
              Icon(Icons.access_time_rounded,
                  size: 14, color: cs.onSurfaceVariant),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  df.format(project.updatedAt),
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
                ),
              ),
            ],
          ),
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (v) async {
            switch (v) {
              case 'open':
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => EditorScreen(project: project),
                ));
                break;
              case 'rename':
                _renameDialog(context);
                break;
              case 'delete':
                _confirmDelete(context);
                break;
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem(value: 'open', child: Text(l10n.open)),
            PopupMenuItem(value: 'rename', child: Text(l10n.rename)),
            PopupMenuItem(
              value: 'delete',
              child: Text(l10n.delete,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EditorScreen(project: project),
          ));
        },
      ),
    );
  }

  void _renameDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: project.name);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.renameProject),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.projectName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              await Provider.of<ProjectsProvider>(context, listen: false)
                  .rename(project, name);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l10n.done),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProjectTitle),
        content: Text(l10n.deleteProjectMessage(project.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              await Provider.of<ProjectsProvider>(context, listen: false)
                  .delete(project);
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
