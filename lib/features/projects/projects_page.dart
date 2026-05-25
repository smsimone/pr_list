import 'package:flutter/material.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/projects/project_form_dialog.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

class ProjectsPage extends ConsumerWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(projectsNotifierProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return EmptyState(message: l10n.emptyProjects);
    }
    return ResponsiveContainer(
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: state.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final project = state.items[index];
          final prState = ref.watch(prListNotifierProvider);
          final prCount = prState.items
              .where((pr) => pr.projectAlias == project.alias)
              .length;

          Color textColor = Colors.white;
          Color? prjColor;
          if (project.color != null) {
            prjColor = Color(project.color!);
            if (prjColor.computeLuminance() > 0.4) {
              textColor = Colors.black;
            }
          }

          return Card(
            child: ListTile(
              leading: Stack(
                alignment: AlignmentDirectional.center,
                children: [
                  if (prjColor != null)
                    CircleAvatar(backgroundColor: prjColor, radius: 14),
                  Text(
                    '$prCount',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              title: Text(project.alias),
              subtitle: Text(project.path),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (_) => ProjectFormDialog(existing: project),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () =>
                        _confirmDeleteProject(context, ref, project.id),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDeleteProject(
    BuildContext context,
    WidgetRef ref,
    int projectId,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteProjectTitle),
        content: Text(l10n.deleteProjectMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    final result = await ref
        .read(projectsNotifierProvider.notifier)
        .deleteProject(projectId);
    if (result.isLeft && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericDeleteError)));
    }
  }
}
