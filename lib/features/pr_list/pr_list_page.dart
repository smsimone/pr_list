import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/settings/pat_settings_dialog.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

enum _PrLane { unreleased, develop, uat, preprod }

class PrListPage extends ConsumerWidget {
  const PrListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final state = ref.watch(prListNotifierProvider);
    final PrListViewMode viewMode = ref.watch(prListViewModeProvider);
    final nextRunAsync = ref.watch(schedulerNextRunProvider);
    final bool isSyncRunning = ref.watch(prSyncServiceProvider).isSyncRunning;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tabPrList),
        actions: <Widget>[
          TextButton.icon(
            onPressed: isSyncRunning
                ? null
                : () async {
                    final Future<void> Function() triggerSync = ref.read(
                      triggerPrSyncProvider,
                    );
                    await triggerSync();
                  },
            icon: const Icon(Icons.schedule),
            label: Text(_buildSchedulerLabel(l10n, nextRunAsync.value)),
          ),
          IconButton(
            tooltip: viewMode == PrListViewMode.groupedList
                ? l10n.viewKanban
                : l10n.viewList,
            onPressed: () {
              ref
                  .read(prListViewModeProvider.notifier)
                  .state = viewMode == PrListViewMode.groupedList
                  ? PrListViewMode.kanban
                  : PrListViewMode.groupedList;
            },
            icon: Icon(
              viewMode == PrListViewMode.groupedList
                  ? Icons.view_kanban
                  : Icons.view_list,
            ),
          ),
          IconButton(
            onPressed: () => showDialog(
              context: context,
              builder: (_) => const PatSettingsDialog(),
            ),
            icon: const Icon(Icons.vpn_key),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () =>
            showDialog(context: context, builder: (_) => const PrFormDialog()),
        child: const Icon(Icons.add),
      ),
      body: Builder(
        builder: (context) {
          if (state.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.items.isEmpty) {
            return EmptyState(message: l10n.emptyState);
          }

          return ResponsiveContainer(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: viewMode == PrListViewMode.groupedList
                  ? _GroupedPrList(prs: state.items)
                  : _KanbanPrList(prs: state.items),
            ),
          );
        },
      ),
    );
  }

  String _buildSchedulerLabel(AppLocalizations l10n, DateTime? nextRun) {
    if (nextRun == null) {
      return l10n.schedulerNotScheduled;
    }
    final Duration remaining = nextRun.difference(DateTime.now());
    final Duration positive = remaining.isNegative ? Duration.zero : remaining;
    final int minutes = positive.inMinutes;
    final int seconds = positive.inSeconds.remainder(60);
    return l10n.schedulerCountdown(minutes, seconds);
  }
}

class _GroupedPrList extends ConsumerWidget {
  final List<PullRequest> prs;

  const _GroupedPrList({required this.prs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Map<_PrLane, List<PullRequest>> grouped = _groupByLane(prs);
    final List<_PrLane> orderedLanes = <_PrLane>[
      _PrLane.unreleased,
      _PrLane.develop,
      _PrLane.uat,
      _PrLane.preprod,
    ];

    return ListView.builder(
      itemCount: orderedLanes.length,
      itemBuilder: (BuildContext context, int index) {
        final _PrLane lane = orderedLanes[index];
        final List<PullRequest> laneItems = grouped[lane] ?? <PullRequest>[];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                _laneLabel(l10n, lane),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (laneItems.isEmpty)
                Text(l10n.emptyState)
              else
                ...laneItems.map(
                  (PullRequest pr) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: _PrCard(pr: pr),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanPrList extends ConsumerWidget {
  final List<PullRequest> prs;

  const _KanbanPrList({required this.prs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final Map<_PrLane, List<PullRequest>> grouped = _groupByLane(prs);
    final List<_PrLane> lanes = <_PrLane>[
      _PrLane.unreleased,
      _PrLane.develop,
      _PrLane.uat,
      _PrLane.preprod,
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: lanes.map((lane) {
          final List<PullRequest> laneItems = grouped[lane] ?? <PullRequest>[];
          return Container(
            width: 280,
            margin: const EdgeInsets.only(right: 12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      _laneLabel(l10n, lane),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: laneItems.isEmpty
                          ? Text(l10n.emptyState)
                          : ListView.builder(
                              itemCount: laneItems.length,
                              itemBuilder: (BuildContext context, int index) {
                                final PullRequest pr = laneItems[index];
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _PrCard(pr: pr),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PrCard extends ConsumerWidget {
  final PullRequest pr;

  const _PrCard({required this.pr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        title: Text('${pr.projectAlias} • ${pr.branch}'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (pr.jiraTicket != null)
              Text('${l10n.jiraTicket}: ${pr.jiraTicket}'),
            if (pr.prLink != null) Text('${l10n.prLink}: ${pr.prLink}'),
            if (pr.providerStatus != null)
              Text('${l10n.providerStatus}: ${pr.providerStatus}'),
            if (pr.lastCommitSha != null)
              Text('${l10n.lastCommit}: ${pr.lastCommitSha}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => showDialog(
                context: context,
                builder: (_) => PrFormDialog(existing: pr),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context, ref, pr.id),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    int id,
  ) async {
    final AppLocalizations l10n = AppLocalizations.of(context)!;
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(l10n.deletePrTitle),
        content: Text(l10n.deletePrMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (shouldDelete != true || !context.mounted) {
      return;
    }
    final result = await ref.read(prListNotifierProvider.notifier).deletePr(id);
    if (result.isLeft && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericDeleteError)));
    }
  }
}

Map<_PrLane, List<PullRequest>> _groupByLane(List<PullRequest> prs) {
  final Map<_PrLane, List<PullRequest>> grouped = <_PrLane, List<PullRequest>>{
    _PrLane.unreleased: <PullRequest>[],
    _PrLane.develop: <PullRequest>[],
    _PrLane.uat: <PullRequest>[],
    _PrLane.preprod: <PullRequest>[],
  };

  for (final PullRequest pr in prs) {
    grouped[_resolveLane(pr)]!.add(pr);
  }
  return grouped;
}

_PrLane _resolveLane(PullRequest pr) {
  if (pr.isOnPreprod) {
    return _PrLane.preprod;
  }
  if (pr.isOnUat) {
    return _PrLane.uat;
  }
  if (pr.isOnDevelop) {
    return _PrLane.develop;
  }
  return _PrLane.unreleased;
}

String _laneLabel(AppLocalizations l10n, _PrLane lane) {
  switch (lane) {
    case _PrLane.unreleased:
      return l10n.laneUnreleased;
    case _PrLane.develop:
      return l10n.laneDev;
    case _PrLane.uat:
      return l10n.laneUat;
    case _PrLane.preprod:
      return l10n.lanePreprod;
  }
}
