import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/environment_mapping_repository.dart';

final envMappingRepositoryProvider = Provider<EnvironmentMappingRepository>(
  (ref) => getIt<EnvironmentMappingRepository>(),
);

final envMappingsProvider = FutureProvider<List<EnvironmentMapping>>((ref) async {
  final repo = ref.watch(envMappingRepositoryProvider);
  final result = await repo.getAll();
  if (result.isLeft) {
    return <EnvironmentMapping>[];
  }
  return result.right;
});
