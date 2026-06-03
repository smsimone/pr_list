
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';
import 'package:pr_list/features/settings/env_mapping_providers.dart';
import 'package:pr_list/shared/utils/ticket_utils.dart';

enum PrListViewMode { groupedList, kanban }

enum TicketStatusFilter { all, open, closed, withoutTicket }

class PrListFilter {
  final Set<String> selectedProjectAliases;
  final TicketStatusFilter ticketStatus;
  final String ticketQuery;

  const PrListFilter({
    this.selectedProjectAliases = const {},
    this.ticketStatus = TicketStatusFilter.all,
    this.ticketQuery = '',
  });

  PrListFilter copyWith({
    Set<String>? selectedProjectAliases,
    TicketStatusFilter? ticketStatus,
    String? ticketQuery,
  }) {
    return PrListFilter(
      selectedProjectAliases:
          selectedProjectAliases ?? this.selectedProjectAliases,
      ticketStatus: ticketStatus ?? this.ticketStatus,
      ticketQuery: ticketQuery ?? this.ticketQuery,
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

final prRepositoryProvider = Provider<PrRepository>((ref) => getIt<PrRepository>());

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

final syncRunningSinceProvider = StreamProvider<Duration?>((ref) {
  final syncService = ref.watch(prSyncServiceProvider);
  return syncService.syncRunningSinceStream;
});

final triggerPrSyncProvider = Provider<Future<void> Function()>(
  (ref) =>
      () async => ref.read(prSyncServiceProvider).triggerNowAndReset(),
);

final prListViewModeProvider = StateProvider<PrListViewMode>(
  (ref) => PrListViewMode.kanban,
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

    if (!matchesTicketQuery(pr, filter.ticketQuery)) {
      return false;
    }

    return true;
  }).toList();
});

bool matchesTicketQuery(PullRequest pr, String ticketQuery) {
  final normalizedTicketQuery = ticketQuery.trim().toLowerCase();
  if (normalizedTicketQuery.isEmpty) {
    return true;
  }

  final ticketLink = pr.jiraTicket;
  if (ticketLink == null || ticketLink.trim().isEmpty) {
    return false;
  }

  final extractedTicket = extractTicketName(ticketLink).toLowerCase();
  final rawTicketLink = ticketLink.toLowerCase();
  return extractedTicket.contains(normalizedTicketQuery) ||
      rawTicketLink.contains(normalizedTicketQuery);
}

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
