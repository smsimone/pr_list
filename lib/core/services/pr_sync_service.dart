import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/git_provider.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class PrSyncService {
  static const Duration _kSyncInterval = Duration(minutes: 10);

  final PrRepository _repository;
  final ProviderRegistry _providerRegistry;
  final GitClient _gitClient;
  final SecureStorageService _secureStorage;
  final ProjectRepository _projectRepository;
  final Logger _logger;
  Timer? _pollingTimer;

  PrSyncService(
    this._repository,
    this._providerRegistry,
    this._gitClient,
    this._secureStorage,
    this._projectRepository,
    this._logger,
  );

  void start() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(_kSyncInterval, (_) => _syncAll());
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> _syncAll() async {
    _logger.info('Starting PR sync');
    final Either<Failure, List<PullRequest>> result = await _loadPullRequests();
    if (result.isLeft) {
      _logger.warning('Failed to load PRs');
      return;
    }

    for (final PullRequest pr in result.right) {
      if (pr.prLink == null || pr.prLink!.trim().isEmpty) {
        continue;
      }
      final provider = _providerRegistry.match(pr.prLink!);
      if (provider == null) {
        continue;
      }

      final Either<Failure, String?> patResult = await _loadPat();
      if (patResult.isLeft) {
        _logger.warning('PAT read error');
        continue;
      }
      final String? pat = patResult.right;
      if (pat == null || pat.trim().isEmpty) {
        _logger.warning('PAT missing');
        continue;
      }

      final Either<Failure, void> syncResult = await _syncProvider(
        pr,
        provider,
        pat,
      );
      if (syncResult.isLeft) {
        _logger.warning('Sync provider failed');
        continue;
      }

      final String? updatedStatus = await _loadProviderStatus(pr.id);
      if (updatedStatus == 'completed') {
        final String? lastCommit = await _loadLastCommit(pr.id);
        final String? workingDir = await _resolveWorkingDirectory(pr);
        await _syncEnvironments(pr.id, lastCommit, workingDir);
      }
    }
  }

  Future<Either<Failure, List<PullRequest>>> _loadPullRequests() async {
    try {
      final List<PullRequest> prs = await _repository.watchAll().first;
      return Either.right(prs);
    } catch (err) {
      return Either.left(Failure(message: 'Failed to load PRs', cause: err));
    }
  }

  Future<Either<Failure, String?>> _loadPat() async {
    final result = await _secureStorage.getAzurePat();
    if (result.isLeft) {
      return Either.left(result.left);
    }
    return Either.right(result.right);
  }

  Future<Either<Failure, void>> _syncProvider(
    PullRequest pr,
    GitProvider provider,
    String pat,
  ) async {
    final infoResult = await provider.fetchPullRequestInfo(
      url: pr.prLink!,
      pat: pat,
    );
    if (infoResult.isLeft) {
      return Either.left(infoResult.left);
    }
    final info = infoResult.right;
    final updateResult = await _repository.updateProviderInfo(
      id: pr.id,
      provider: info.provider,
      providerPrId: info.pullRequestId,
      providerStatus: info.status,
      lastCommitSha: info.lastCommitSha,
    );
    if (updateResult.isLeft) {
      return Either.left(updateResult.left);
    }
    return const Either.right(null);
  }

  Future<void> _syncEnvironments(
    int prId,
    String? lastCommitSha,
    String? workingDirectory,
  ) async {
    if (lastCommitSha == null || lastCommitSha.trim().isEmpty) {
      return;
    }
    if (workingDirectory == null || workingDirectory.trim().isEmpty) {
      _logger.warning('Missing working directory for git command');
      return;
    }
    final result = await _gitClient.branchesContainingCommit(
      lastCommitSha,
      workingDirectory: workingDirectory,
    );
    if (result.isLeft) {
      _logger.warning('git branch contains failed');
      return;
    }
    final List<String> branches = result.right;
    final bool isOnDevelop = branches.any((b) => b.endsWith('/develop'));
    final bool isOnUat = branches.any((b) => b.endsWith('/uat'));
    final bool isOnPreprod = branches.any((b) => b.endsWith('/preprod'));

    await _repository.updateEnvironmentFlags(
      id: prId,
      isOnDevelop: isOnDevelop,
      isOnUat: isOnUat,
      isOnPreprod: isOnPreprod,
    );
  }

  Future<String?> _loadProviderStatus(int id) async {
    final result = await _repository.getById(id);
    if (result.isLeft) {
      return null;
    }
    return result.right?.providerStatus;
  }

  Future<String?> _loadLastCommit(int id) async {
    final result = await _repository.getById(id);
    if (result.isLeft) {
      return null;
    }
    return result.right?.lastCommitSha;
  }

  Future<String?> _resolveWorkingDirectory(PullRequest pr) async {
    if (pr.projectAlias.trim().isEmpty) {
      return null;
    }
    final result = await _projectRepository.getByAlias(pr.projectAlias);
    if (result.isLeft) {
      return null;
    }
    return result.right?.path;
  }
}
