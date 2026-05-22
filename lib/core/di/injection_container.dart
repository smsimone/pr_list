import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/azure_devops_provider.dart';
import 'package:pr_list/core/services/branch_cache_service.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/git_provider.dart';
import 'package:pr_list/core/services/local_git_client.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

final GetIt getIt = GetIt.instance;

Future<Either<Failure, void>> initDependencies() async {
  try {
    getIt.registerLazySingleton<Logger>(() => Logger('PrList'));

    getIt.registerLazySingleton<AppDatabase>(AppDatabase.new);
    getIt.registerLazySingleton<PrRepository>(
      () => PrRepository(getIt<AppDatabase>()),
    );
    getIt.registerLazySingleton<ProjectRepository>(
      () => ProjectRepository(getIt<AppDatabase>()),
    );

    getIt.registerLazySingleton<GitProvider>(AzureDevOpsProvider.new);
    getIt.registerLazySingleton<ProviderRegistry>(
      () => ProviderRegistry(<GitProvider>[getIt<GitProvider>()]),
    );
    getIt.registerLazySingleton<GitClient>(LocalGitClient.new);
    getIt.registerLazySingleton<BranchCacheService>(
      () => BranchCacheService(getIt<GitClient>()),
    );

    getIt.registerLazySingleton<SecureStorageService>(
      () => SecureStorageService(const FlutterSecureStorage()),
    );

    getIt.registerLazySingleton<PrSyncService>(
      () => PrSyncService(
        getIt<PrRepository>(),
        getIt<ProviderRegistry>(),
        getIt<GitClient>(),
        getIt<SecureStorageService>(),
        getIt<ProjectRepository>(),
        getIt<Logger>(),
      ),
    );

    return const Either.right(null);
  } catch (err) {
    return Either.left(
      Failure(message: 'Dependency initialization failed', cause: err),
    );
  }
}
