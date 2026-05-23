import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/projects/projects_providers.dart';
import 'package:pr_list/features/settings/env_mapping_providers.dart';
import 'package:pr_list/shared/widgets/empty_state.dart';
import 'package:pr_list/shared/widgets/responsive_container.dart';

enum _PrLane { unreleased, develop, uat, preprod }

class PrListPage extends ConsumerWidget {
  const PrListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(prListNotifierProvider);
    final viewMode = ref.watch(prListViewModeProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.items.isEmpty) {
      return EmptyState(message: l10n.emptyState);
    }

    if (viewMode == PrListViewMode.groupedList) {
      return ResponsiveContainer(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _GroupedPrList(prs: state.items),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: _KanbanPrList(prs: state.items),
    );
  }
}

class _GroupedPrList extends ConsumerWidget {
  final List<PullRequest> prs;

  const _GroupedPrList({required this.prs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final grouped = _groupByLane(prs);
    final orderedLanes = [
      _PrLane.unreleased,
      _PrLane.develop,
      _PrLane.uat,
      _PrLane.preprod,
    ];
    final envMappingsAsync = ref.watch(envMappingsProvider);

    return ListView.builder(
      itemCount: orderedLanes.length,
      itemBuilder: (context, index) {
        final lane = orderedLanes[index];
        final laneItems = grouped[lane] ?? [];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _laneLabel(l10n, lane, envMappingsAsync),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (laneItems.isEmpty)
                Text(l10n.emptyState)
              else
                ...laneItems.map(
                  (pr) => Padding(
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

class _KanbanPrList extends ConsumerStatefulWidget {
  final List<PullRequest> prs;

  const _KanbanPrList({required this.prs});

  @override
  ConsumerState<_KanbanPrList> createState() => _KanbanPrListState();
}

class _KanbanPrListState extends ConsumerState<_KanbanPrList> {
  final _scrollController = ScrollController();
  late AppLocalizations _l10n;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _l10n = AppLocalizations.of(context)!;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupByLane(widget.prs);
    final lanes = [
      _PrLane.unreleased,
      _PrLane.develop,
      _PrLane.uat,
      _PrLane.preprod,
    ];
    final envMappingsAsync = ref.watch(envMappingsProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        const double gap = 12;
        final laneCount = lanes.length;
        final totalGaps = gap * (laneCount - 1);
        final idealWidth =
            (constraints.maxWidth - totalGaps) / laneCount;
        final laneWidth = idealWidth.clamp(240.0, 350.0);

        final totalWidth = laneWidth * laneCount + totalGaps;

        final columns = lanes.map((lane) {
          final laneItems =
              grouped[lane] ?? [];
          return Container(
            width: laneWidth,
            margin: EdgeInsets.only(right: lane == lanes.last ? 0 : gap),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _laneLabel(_l10n, lane, envMappingsAsync),
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: laneItems.isEmpty
                          ? Text(_l10n.emptyState)
                          : ListView.builder(
                              itemCount: laneItems.length,
                              itemBuilder:
                                  (context, index) {
                                final pr = laneItems[index];
                                return Padding(
                                  padding:
                                      const EdgeInsets.only(bottom: 8),
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
        }).toList();

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: columns,
        );

        if (totalWidth > constraints.maxWidth) {
          return Scrollbar(
            thumbVisibility: true,
            controller: _scrollController,
            child: SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: row,
            ),
          );
        }

        return row;
      },
    );
  }
}

class _PrCard extends ConsumerWidget {
  final PullRequest pr;

  const _PrCard({required this.pr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final projects = ref.watch(projectsNotifierProvider).items;
    final project = projects.where((p) => p.alias == pr.projectAlias).firstOrNull;
    final color = project?.color;
    return Card(
      child: ListTile(
        title: Row(
          children: [
            if (color != null)
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Container(
                  width: 10, height: 10,
                  decoration: BoxDecoration(
                    color: Color(color),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Flexible(child: Text('${pr.projectAlias} • ${pr.branch}',
                overflow: TextOverflow.ellipsis)),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (pr.jiraTicket != null)
              Row(
                children: [
                  Icon(
                    pr.isTicketClosed
                        ? Icons.check_circle
                        : Icons.circle_outlined,
                    size: 16,
                    color: pr.isTicketClosed ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text('${l10n.jiraTicket}: ${pr.jiraTicket}',
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            if (pr.prLink != null)
              Text('${l10n.prLink}: ${pr.prLink}',
                  overflow: TextOverflow.ellipsis),
            if (pr.providerStatus != null)
              Text('${l10n.providerStatus}: ${pr.providerStatus}',
                  overflow: TextOverflow.ellipsis),
            if (pr.lastCommitSha != null)
              Text('${l10n.lastCommit}: ${pr.lastCommitSha}',
                  overflow: TextOverflow.ellipsis),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
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
    final l10n = AppLocalizations.of(context)!;
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deletePrTitle),
        content: Text(l10n.deletePrMessage),
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
    final result = await ref.read(prListNotifierProvider.notifier).deletePr(id);
    if (result.isLeft && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.genericDeleteError)));
    }
  }
}

Map<_PrLane, List<PullRequest>> _groupByLane(List<PullRequest> prs) {
  final grouped = <_PrLane, List<PullRequest>>{
    _PrLane.unreleased: <PullRequest>[],
    _PrLane.develop: <PullRequest>[],
    _PrLane.uat: <PullRequest>[],
    _PrLane.preprod: <PullRequest>[],
  };

  for (final pr in prs) {
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

String _laneLabel(
  AppLocalizations l10n,
  _PrLane lane, [
  AsyncValue<List<EnvironmentMapping>>? envMappingsAsync,
]) {
  final List<EnvironmentMapping>? mappings =
      envMappingsAsync?.valueOrNull;
  switch (lane) {
    case _PrLane.unreleased:
      return l10n.laneUnreleased;
    case _PrLane.develop:
      if (mappings != null && mappings.isNotEmpty) {
        final name = mappings[0].environmentName.trim();
        if (name.isNotEmpty) return name;
      }
      return l10n.laneDev;
    case _PrLane.uat:
      if (mappings != null && mappings.length > 1) {
        final name = mappings[1].environmentName.trim();
        if (name.isNotEmpty) return name;
      }
      return l10n.laneUat;
    case _PrLane.preprod:
      if (mappings != null && mappings.length > 2) {
        final name = mappings[2].environmentName.trim();
        if (name.isNotEmpty) return name;
      }
      return l10n.lanePreprod;
  }
}
