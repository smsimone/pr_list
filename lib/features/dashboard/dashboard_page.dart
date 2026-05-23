import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/dashboard/dashboard_provider.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final stateAsync = ref.watch(dashboardProvider);

    return stateAsync.when(
      data: (state) {
        return ResponsiveContainer(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _DashboardColumn(
                    title: l10n.dashboardUnreleased,
                    prs: state.notReleased,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DashboardColumn(
                    title: l10n.dashboardUnclosed,
                    prs: state.notClosed,
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

class _DashboardColumn extends StatelessWidget {
  final String title;
  final List<PullRequest> prs;

  const _DashboardColumn({required this.title, required this.prs});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
                      itemCount: prs.length,
                      itemBuilder: (context, index) {
                        final pr = prs[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Card(
                            child: ListTile(
                              title: Text(
                                pr.projectAlias,
                              ),
                              subtitle: pr.jiraTicket == null
                                  ? null
                                  : Text(pr.jiraTicket!),
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
