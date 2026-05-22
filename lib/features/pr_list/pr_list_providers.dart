import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';

enum PrListViewMode { groupedList, kanban }

final prListNotifierProvider =
    StateNotifierProvider<PrListNotifier, PrListState>(
      (ref) => PrListNotifier(
        getIt<PrRepository>(),
        getIt<ProviderRegistry>(),
        getIt<ProjectRepository>(),
        getIt<GitClient>(),
      ),
    );

final prSyncServiceProvider = Provider<PrSyncService>(
  (ref) => getIt<PrSyncService>(),
);

final schedulerNextRunProvider = StreamProvider<DateTime?>((ref) {
  final PrSyncService syncService = ref.watch(prSyncServiceProvider);
  return syncService.nextRunStream;
});

final triggerPrSyncProvider = Provider<Future<void> Function()>(
  (ref) =>
      () async => ref.read(prSyncServiceProvider).triggerNowAndReset(),
);

final prListViewModeProvider = StateProvider<PrListViewMode>(
  (ref) => PrListViewMode.groupedList,
);
