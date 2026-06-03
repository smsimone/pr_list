import 'dart:async';

import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/environment_mapping_repository.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/git_provider.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/core/services/secure_storage_service.dart';
import 'package:pr_list/core/services/ticket_provider_registry.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

enum _SyncResult { ok, error, skipped }

const _kMaxConcurrentSyncs = 5;

class PrSyncService {
  static const _kSyncInterval = Duration(minutes: 10);

  final PrRepository _repository;
  final ProviderRegistry _providerRegistry;
  final TicketProviderRegistry _ticketProviderRegistry;
  final GitClient _gitClient;
  final SecureStorageService _secureStorage;
  final ProjectRepository _projectRepository;
  final EnvironmentMappingRepository _envMappingRepository;
  final Logger _logger;
  Timer? _pollingTimer;
  Timer? _countdownTickTimer;
  DateTime? _nextRunAt;
  final StreamController<DateTime?> _nextRunController =
      StreamController<DateTime?>.broadcast();
  bool _isSyncRunning = false;
  DateTime? _syncStartedAt;
  Timer? _syncCountdownTimer;
  final StreamController<Duration?> _syncRunningSinceController =
      StreamController<Duration?>.broadcast();

  PrSyncService(
    this._repository,
    this._providerRegistry,
    this._ticketProviderRegistry,
    this._gitClient,
    this._secureStorage,
    this._projectRepository,
    this._envMappingRepository,
    this._logger,
  );

  Stream<DateTime?> get nextRunStream => _nextRunController.stream;
  DateTime? get nextRunAt => _nextRunAt;
  bool get isSyncRunning => _isSyncRunning;
  Stream<Duration?> get syncRunningSinceStream =>
      _syncRunningSinceController.stream;

  void start() {
    _schedulePeriodicSync();
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTickTimer?.cancel();
    _countdownTickTimer = null;
    _syncCountdownTimer?.cancel();
    _syncCountdownTimer = null;
    _syncStartedAt = null;
    _syncRunningSinceController.add(null);
    _nextRunAt = null;
    _nextRunController.add(null);
  }

  Future<void> triggerNowAndReset() async {
    if (_isSyncRunning) {
      return;
    }
    _pollingTimer?.cancel();
    _countdownTickTimer?.cancel();
    _nextRunAt = null;
    _nextRunController.add(null);
    await _syncAll();
    _schedulePeriodicSync();
  }

  Future<Either<Failure, void>> verifyEnvironmentsForPr(int prId) async {
    if (_isSyncRunning) {
      return const Either.left(Failure(message: 'Sync already in progress'));
    }
    _isSyncRunning = true;
    try {
      final prResult = await _repository.getById(prId);
      if (prResult.isLeft || prResult.right == null) {
        return Either.left(
          Failure(message: '[PR#$prId] not found'),
        );
      }
      final pr = prResult.right!;
      if (pr.isManual) {
        _logger.info('[PR#$prId] manual mode enabled, skipping environment check');
        return const Either.right(null);
      }
      final lastCommit = await _loadLastCommit(pr.id);
      final mergeCommit = await _loadMergeCommit(pr.id);
      final workingDir = await _resolveWorkingDirectory(pr);
      await _syncEnvironments(pr.id, lastCommit, mergeCommit, workingDir);
      return const Either.right(null);
    } finally {
      _isSyncRunning = false;
    }
  }

  Future<void> _syncAll() async {
    if (_isSyncRunning) {
      _logger.info('PR sync already in progress, skipping');
      return;
    }
    _isSyncRunning = true;
    _syncStartedAt = DateTime.now();
    _syncCountdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _syncRunningSinceController
          .add(DateTime.now().difference(_syncStartedAt!));
    });
    _syncRunningSinceController.add(Duration.zero);
    final stopwatch = Stopwatch()..start();
    int ok = 0, errors = 0, skipped = 0;
    try {
      _logger.info('Starting PR sync');
      final result = await _loadPullRequests();
      if (result.isLeft) {
        _logger.warning('Failed to load PRs: ${result.left.message}');
        return;
      }

      final prs = result.right;
      _logger.info('Loaded ${prs.length} PR(s) to sync');

      final patResult = await _loadPat();
      if (patResult.isLeft) {
        _logger.warning('PAT read error: ${patResult.left.message}');
        return;
      }
      final pat = patResult.right;
      if (pat == null || pat.trim().isEmpty) {
        _logger.warning('PAT is empty, aborting sync');
        return;
      }

      for (int i = 0; i < prs.length; i += _kMaxConcurrentSyncs) {
        final end = (i + _kMaxConcurrentSyncs > prs.length)
            ? prs.length
            : i + _kMaxConcurrentSyncs;
        final batch = prs.sublist(i, end);
        final batchResults = await Future.wait(
          batch.map((pr) => _syncOnePr(pr, pat)),
        );
        for (final r in batchResults) {
          switch (r) {
            case _SyncResult.ok:
              ok++;
            case _SyncResult.error:
              errors++;
            case _SyncResult.skipped:
              skipped++;
          }
        }
      }
    } finally {
      _isSyncRunning = false;
      _syncCountdownTimer?.cancel();
      _syncCountdownTimer = null;
      _syncStartedAt = null;
      _syncRunningSinceController.add(null);
      final elapsed = stopwatch.elapsedMilliseconds;
      _logger.info(
        'PR sync finished: $ok OK, $errors errors, $skipped skipped in ${elapsed}ms',
      );
    }
  }

  Future<_SyncResult> _syncOnePr(PullRequest pr, String pat) async {
    final prLabel = '[PR#${pr.id}]';
    try {
      if (pr.prLink == null || pr.prLink!.trim().isEmpty) {
        _logger.info('$prLabel: no PR link, skipping');
        return _SyncResult.skipped;
      }
      final provider = _providerRegistry.match(pr.prLink!);
      if (provider == null) {
        _logger.warning('$prLabel: no provider supports URL ${pr.prLink}');
        return _SyncResult.skipped;
      }
      _logger.info('$prLabel: matched provider ${provider.name}');

      _logger.info('$prLabel: fetching provider info...');
      final syncResult = await _syncProvider(pr, provider, pat);
      if (syncResult.isLeft) {
        _logger.warning('$prLabel: sync failed: ${syncResult.left.message}');
        return _SyncResult.error;
      }
      _logger.info('$prLabel: provider info updated successfully');

      final updatedStatus = await _loadProviderStatus(pr.id);
      if (updatedStatus == 'completed') {
        _logger.info('$prLabel: status is completed, checking environments...');
        final isManual = await _loadIsManual(pr.id);
        if (isManual == true) {
          _logger.info('$prLabel: manual mode enabled, skipping environment check');
        } else {
          final lastCommit = await _loadLastCommit(pr.id);
          final mergeCommit = await _loadMergeCommit(pr.id);
          final workingDir = await _resolveWorkingDirectory(pr);
          await _syncEnvironments(pr.id, lastCommit, mergeCommit, workingDir);
        }
      } else {
        _logger.info('$prLabel: status=$updatedStatus, skipping environment check');
      }

      if (pr.jiraTicket != null && pr.jiraTicket!.trim().isNotEmpty) {
        _logger.info('$prLabel: syncing ticket status...');
        await _syncTicketStatus(pr.id, pr.jiraTicket!);
      }

      return _SyncResult.ok;
    } catch (err) {
      _logger.severe('$prLabel: unexpected error: $err');
      return _SyncResult.error;
    }
  }

  Future<Either<Failure, List<PullRequest>>> _loadPullRequests() async {
    try {
      final prs = await _repository.watchAll().first;
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
    final prLabel = '[PR#${pr.id}]';
    _logger.info('$prLabel: calling ${provider.name} API...');

    String? remoteUrl;
    if (pr.projectAlias.trim().isNotEmpty) {
      final projectResult = await _projectRepository.getByAlias(pr.projectAlias);
      if (projectResult.isRight && projectResult.right != null) {
        final path = projectResult.right!.path;
        final remoteResult = await _gitClient.getRemoteUrl(
          workingDirectory: path,
          prId: pr.id.toString(),
        );
        if (remoteResult.isRight) {
          remoteUrl = remoteResult.right;
          _logger.info('$prLabel: resolved remote URL: $remoteUrl');
        }
      }
    }

    final infoResult = await provider.fetchPullRequestInfo(
      url: pr.prLink!,
      pat: pat,
      remoteUrl: remoteUrl,
    );
    if (infoResult.isLeft) {
      _logger.warning('$prLabel: provider API error: ${infoResult.left.message}');
      return Either.left(infoResult.left);
    }
    final info = infoResult.right;
    _logger.info(
      '$prLabel: provider response -> status=${info.status}, '
      'commitSha=${info.lastCommitSha}, '
      'mergeCommitSha=${info.lastMergeCommitSha ?? '(none)'}',
    );
    final updateResult = await _repository.updateProviderInfo(
      id: pr.id,
      provider: info.provider,
      providerPrId: info.pullRequestId,
      providerStatus: info.status,
      lastCommitSha: info.lastCommitSha,
      lastMergeCommitSha: info.lastMergeCommitSha,
    );
    if (updateResult.isLeft) {
      _logger.warning('$prLabel: DB update failed: ${updateResult.left.message}');
      return Either.left(updateResult.left);
    }
    return const Either.right(null);
  }

  Future<void> _syncEnvironments(
    int prId,
    String? lastCommitSha,
    String? lastMergeCommitSha,
    String? workingDirectory,
  ) async {
    final prLabel = '[PR#$prId]';
    if (workingDirectory == null || workingDirectory.trim().isEmpty) {
      _logger.warning('$prLabel: missing working directory for git command');
      return;
    }

    final targetSha = (lastMergeCommitSha != null &&
            lastMergeCommitSha.trim().isNotEmpty)
        ? lastMergeCommitSha
        : lastCommitSha;
    if (targetSha == null || targetSha.trim().isEmpty) {
      _logger.info('$prLabel: no commit SHA, skipping environment check');
      return;
    }

    _logger.info(
      '$prLabel: checking branches for $targetSha '
      '(source=$lastCommitSha, merge=$lastMergeCommitSha) in $workingDirectory',
    );

    final candidateShas = <String>{targetSha};
    if (lastCommitSha != null &&
        lastCommitSha.trim().isNotEmpty &&
        lastCommitSha != targetSha) {
      candidateShas.add(lastCommitSha);
    }

    final envMappingsResult = await _envMappingRepository.getAll();
    List<EnvironmentMapping> mappings;
    if (envMappingsResult.isLeft) {
      _logger.warning(
        '$prLabel: failed to load env mappings, using defaults',
      );
      mappings = _defaultMappings();
    } else {
      mappings = envMappingsResult.right;
    }

    final envBranchPatterns = mappings
        .map((m) => m.branchPattern.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final allBranches = <String>{};

    for (final candidateSha in candidateShas) {
      _logger.info('$prLabel: trying candidate SHA $candidateSha');

      final branchesResult = await _gitClient.branchesContainingCommit(
        candidateSha,
        workingDirectory: workingDirectory,
        prId: prId.toString(),
      );
      if (branchesResult.isRight) {
        allBranches.addAll(branchesResult.right);
      }

      final normalizedFound = allBranches
          .map((b) => b.replaceFirst(RegExp(r'^(remotes/)?origin/'), ''))
          .toSet();
      final branchesToCheck = envBranchPatterns
          .where((p) => !normalizedFound.any(
            (b) => b == p,
          ))
          .toList();

      if (branchesToCheck.isEmpty) {
        break;
      }

      final isMergeCandidate = lastMergeCommitSha != null &&
          lastMergeCommitSha.trim().isNotEmpty &&
          candidateSha == lastMergeCommitSha;
      if (isMergeCandidate) {
        _logger.info(
          '$prLabel: running change-id check for branches: $branchesToCheck',
        );
        final changeIdResult = await _gitClient.branchesContainingChangeId(
          candidateSha,
          workingDirectory: workingDirectory,
          onlyBranches: branchesToCheck,
          prId: prId.toString(),
        );
        if (changeIdResult.isRight) {
          allBranches.addAll(changeIdResult.right);
        }
      }
    }

    _logger.info(
      '$prLabel: loaded ${mappings.length} env mapping(s)',
    );
    if (mappings.isNotEmpty) {
      for (final m in mappings) {
        _logger.info(
          '  env#${m.id}: name="${m.environmentName}", pattern="${m.branchPattern}"',
        );
      }
    }

    _logger.info('$prLabel: branches: $allBranches');
    final matchedIds = _resolveMatchedMappingIds(allBranches.toList(), mappings);
    _logger.info('$prLabel: matched env mapping ids: $matchedIds');
    await _repository.setEnvFlags(prId, matchedIds);
  }

  Future<void> _syncTicketStatus(int prId, String ticketUrl) async {
    final prLabel = '[PR#$prId]';
    final provider = _ticketProviderRegistry.match(ticketUrl);
    if (provider == null) {
      _logger.warning('$prLabel: no ticket provider supports URL $ticketUrl');
      return;
    }
    _logger.info('$prLabel: matched ticket provider ${provider.name}');

    String? pat;
    String? instanceUrl;
    String? email;

    if (provider.name == 'jira') {
      final patResult = await _secureStorage.getJiraPat();
      if (patResult.isRight) {
        pat = patResult.right;
      }
      final urlResult = await _secureStorage.getJiraInstanceUrl();
      if (urlResult.isRight) {
        instanceUrl = urlResult.right;
      }
      final emailResult = await _secureStorage.getJiraEmail();
      if (emailResult.isRight) {
        email = emailResult.right;
      }
    }

    if (pat == null || pat.trim().isEmpty) {
      _logger.warning('$prLabel: PAT not configured for ${provider.name}, skipping ticket sync');
      return;
    }

    final infoResult = await provider.fetchTicketInfo(
      url: ticketUrl,
      pat: pat,
      instanceUrl: instanceUrl,
      email: email,
    );
    if (infoResult.isLeft) {
      _logger.warning('$prLabel: ticket sync failed: ${infoResult.left.message}');
      return;
    }

    final info = infoResult.right;
    _logger.info('$prLabel: ticket status -> ${info.status} (closed=${info.isClosed})');
    await _repository.updateTicketStatus(id: prId, ticketStatus: info.status);
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

  Future<String?> _loadMergeCommit(int id) async {
    final result = await _repository.getById(id);
    if (result.isLeft) {
      return null;
    }
    return result.right?.lastMergeCommitSha;
  }

  Future<String?> _resolveWorkingDirectory(PullRequest pr) async {
    if (pr.projectAlias.trim().isEmpty) {
      return null;
    }
    final result = await _projectRepository.getByAlias(pr.projectAlias);
    if (result.isLeft || !result.isRight) {
      return null;
    }
    return result.right?.path;
  }

  Future<bool?> _loadIsManual(int id) async {
    final result = await _repository.getById(id);
    if (result.isLeft || result.right == null) {
      return null;
    }
    return result.right!.isManual;
  }

  void _schedulePeriodicSync() {
    _pollingTimer?.cancel();
    _countdownTickTimer?.cancel();
    _nextRunAt = DateTime.now().add(_kSyncInterval);
    _nextRunController.add(_nextRunAt);
    _countdownTickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _nextRunController.add(_nextRunAt);
    });
    _pollingTimer = Timer.periodic(_kSyncInterval, (_) async {
      await _syncAll();
      _nextRunAt = DateTime.now().add(_kSyncInterval);
      _nextRunController.add(_nextRunAt);
    });
  }

  List<EnvironmentMapping> _defaultMappings() {
    return [
      EnvironmentMapping(
        id: 0,
        sortOrder: 0,
        environmentName: 'Develop',
        branchPattern: 'develop',
      ),
      EnvironmentMapping(
        id: 0,
        sortOrder: 1,
        environmentName: 'UAT',
        branchPattern: 'uat',
      ),
      EnvironmentMapping(
        id: 0,
        sortOrder: 2,
        environmentName: 'Preprod',
        branchPattern: 'preprod',
      ),
    ];
  }

  List<int> _resolveMatchedMappingIds(
    List<String> branches,
    List<EnvironmentMapping> mappings,
  ) {
    return mappings
        .where((m) {
          final pattern = m.branchPattern.trim();
          if (pattern.isEmpty) return false;
          return branches.any((b) => _branchMatchesPattern(b, pattern));
        })
        .map((m) => m.id)
        .toList();
  }

  bool _branchMatchesPattern(String branch, String pattern) {
    final normalized = branch
        .replaceFirst(RegExp(r'^remotes/'), '')
        .replaceFirst(RegExp(r'^origin/'), '');
    return normalized == pattern;
  }

}
