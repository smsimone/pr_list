import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';

final prListNotifierProvider =
    StateNotifierProvider<PrListNotifier, PrListState>(
  (ref) => PrListNotifier(
    getIt<PrRepository>(),
    getIt<ProviderRegistry>(),
  ),
);
