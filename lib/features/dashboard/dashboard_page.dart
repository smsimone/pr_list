import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/dashboard/dashboard_provider.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
import 'package:pr_list/shared/utils/ticket_utils.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

Map<String, PullRequest> _groupByProjectTicket(List<PullRequest> prs) {
  final map = <String, PullRequest>{};
  for (final pr in prs) {
    map['${pr.projectAlias}|${pr.jiraTicket ?? pr.prLink}'] = pr;
  }
  return map;
}

Color? getPrjColor(List<Project> projects, String alias) {
  final index = projects.indexWhere((prj) => prj.alias == alias);
  if (index == -1) return null;
  final col = projects[index].color;
  if (col == null) return null;
  return Color(col);
}

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stateAsync = ref.watch(dashboardProvider);

    return stateAsync.when(
      data: (state) {
        final notReleased = _groupByProjectTicket(state.notReleased);
        final notClosed = _groupByProjectTicket(state.notClosed);
        return ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DashboardColumn(
                    title:
                        '${l10n.dashboardUnreleased} (${notReleased.length})',
                    prs: notReleased.values.toList(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardColumn(
                    title: '${l10n.dashboardUnclosed} (${notClosed.length})',
                    prs: notClosed.values.toList(),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => EmptyState(message: l10n.emptyState),
    );
  }
}

class _DashboardColumn extends ConsumerWidget {
  final String title;
  final List<PullRequest> prs;

  const _DashboardColumn({required this.title, required this.prs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(projectsNotifierProvider).items;

    final groups = <String, List<PullRequest>>{};
    for (final pr in prs) {
      String ticket = "";
      if (pr.jiraTicket != null) {
        ticket = extractTicketName(pr.jiraTicket);
      }
      groups.putIfAbsent(ticket, () => <PullRequest>[]);
      groups[ticket]!.add(pr);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: prs.isEmpty
                  ? EmptyState(message: l10n.emptyState)
                  : ListView.builder(
                      itemCount: groups.keys.length,
                      itemBuilder: (context, index) {
                        final key = groups.keys.toList()[index];
                        final group = groups[key]!;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    key,
                                    // ticketCardTitle(key!),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleSmall,
                                  ),
                                  Text.rich(
                                    TextSpan(
                                      children: group.map((prj) {
                                        return TextSpan(
                                          text: "${prj.projectAlias} ",
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: getPrjColor(
                                                  projects,
                                                  prj.projectAlias,
                                                ),
                                              ),
                                        );
                                      })
                                      .toList(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
