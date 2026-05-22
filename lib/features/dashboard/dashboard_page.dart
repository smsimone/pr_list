import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/features/dashboard/dashboard_provider.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';
import 'package:pr_list/shared/widgets/section_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(true);
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final stateAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabDashboard),
      ),
      body: stateAsync.when(
        data: (state) {
          return ResponsiveContainer(
            child: ListView(
              children: <Widget>[
                SectionCard(
                  title: l10n.dashboardUnreleased,
                  child: state.notReleased.isEmpty
                      ? EmptyState(message: l10n.emptyState)
                      : Column(
                          children: state.notReleased
                              .map(
                                (pr) => ListTile(
                                  title: Text(
                                    '${pr.projectAlias} • ${pr.branch}',
                                  ),
                                  subtitle: pr.jiraTicket == null
                                      ? null
                                      : Text(pr.jiraTicket!),
                                ),
                              )
                              .toList(),
                        ),
                ),
                SectionCard(
                  title: l10n.dashboardUnclosed,
                  child: state.notClosed.isEmpty
                      ? EmptyState(message: l10n.emptyState)
                      : Column(
                          children: state.notClosed
                              .map(
                                (pr) => ListTile(
                                  title: Text(
                                    '${pr.projectAlias} • ${pr.branch}',
                                  ),
                                  subtitle: pr.jiraTicket == null
                                      ? null
                                      : Text(pr.jiraTicket!),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => EmptyState(message: l10n.emptyState),
      ),
    );
  }
}
