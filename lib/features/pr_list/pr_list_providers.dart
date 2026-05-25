
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';
import 'package:pr_list/features/settings/env_mapping_providers.dart';

enum PrListViewMode { groupedList, kanban }

enum TicketStatusFilter { all, open, closed, withoutTicket }

class PrListFilter {
  final Set<String> selectedProjectAliases;
  final TicketStatusFilter ticketStatus;

  const PrListFilter({
    this.selectedProjectAliases = const {},
    this.ticketStatus = TicketStatusFilter.all,
  });

  PrListFilter copyWith({
    Set<String>? selectedProjectAliases,
    TicketStatusFilter? ticketStatus,
  }) {
    return PrListFilter(
      selectedProjectAliases:
          selectedProjectAliases ?? this.selectedProjectAliases,
      ticketStatus: ticketStatus ?? this.ticketStatus,
    );
  }
}

final prListNotifierProvider =
    StateNotifierProvider<PrListNotifier, PrListState>(
      (ref) => PrListNotifier(
        getIt<PrRepository>(),
        getIt<ProviderRegistry>(),
      ),
    );

final prEnvFlagsProvider = FutureProvider<Map<int, List<int>>>((ref) async {
  ref.watch(prListNotifierProvider);
  ref.watch(envMappingsProvider);
  final repo = getIt<PrRepository>();
  final result = await repo.getAllEnvFlags();
  if (result.isLeft) {
    return <int, List<int>>{};
  }
  return result.right;
});

final prSyncServiceProvider = Provider<PrSyncService>(
  (ref) => getIt<PrSyncService>(),
);

final schedulerNextRunProvider = StreamProvider<DateTime?>((ref) {
  final syncService = ref.watch(prSyncServiceProvider);
  return syncService.nextRunStream;
});

final triggerPrSyncProvider = Provider<Future<void> Function()>(
  (ref) =>
      () async => ref.read(prSyncServiceProvider).triggerNowAndReset(),
);

final prListViewModeProvider = StateProvider<PrListViewMode>(
  (ref) => PrListViewMode.groupedList,
);

final prListFilterProvider = StateProvider.autoDispose<PrListFilter>(
  (ref) => const PrListFilter(),
);

final filteredPrListProvider = Provider.autoDispose<List<PullRequest>>((ref) {
  final allPrs = ref.watch(prListNotifierProvider).items;
  final filter = ref.watch(prListFilterProvider);

  return allPrs.where((pr) {
    if (filter.selectedProjectAliases.isNotEmpty &&
        !filter.selectedProjectAliases.contains(pr.projectAlias)) {
      return false;
    }
    switch (filter.ticketStatus) {
      case TicketStatusFilter.all:
        break;
      case TicketStatusFilter.open:
        if (pr.jiraTicket == null || pr.isTicketClosed) return false;
        break;
      case TicketStatusFilter.closed:
        if (pr.jiraTicket == null || !pr.isTicketClosed) return false;
        break;
      case TicketStatusFilter.withoutTicket:
        if (pr.jiraTicket != null) return false;
        break;
    }
    return true;
  }).toList();
});

final duplicatePrIdsProvider = Provider.autoDispose<Set<int>>((ref) {
  final allPrs = ref.watch(prListNotifierProvider).items;
  final seen = <int, List<PullRequest>>{};

  for (final pr in allPrs) {
    final key = Object.hash(pr.projectAlias, pr.jiraTicket, pr.prLink);
    seen.putIfAbsent(key, () => []).add(pr);
  }

  return seen.values
      .where((group) => group.length > 1)
      .expand((group) => group.map((pr) => pr.id))
      .toSet();
});
