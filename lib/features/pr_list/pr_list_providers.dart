import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';
import 'package:pr_list/features/settings/env_mapping_providers.dart';

enum PrListViewMode { groupedList, kanban }

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
