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

  void start() {
    _schedulePeriodicSync();
  }

  void stop() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    _countdownTickTimer?.cancel();
    _countdownTickTimer = null;
    _nextRunAt = null;
    _nextRunController.add(null);
  }

  Future<void> triggerNowAndReset() async {
    if (_isSyncRunning) {
      return;
    }
    await _syncAll();
    _schedulePeriodicSync();
  }

  Future<void> _syncAll() async {
    if (_isSyncRunning) {
      _logger.info('PR sync already in progress, skipping');
      return;
    }
    _isSyncRunning = true;
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

      for (final pr in prs) {
        final prLabel = 'PR #${pr.id} @ ${pr.projectAlias}';
        if (pr.prLink == null || pr.prLink!.trim().isEmpty) {
          _logger.info('$prLabel: no PR link, skipping');
          skipped++;
          continue;
        }
        final provider = _providerRegistry.match(pr.prLink!);
        if (provider == null) {
          _logger.warning('$prLabel: no provider supports URL ${pr.prLink}');
          skipped++;
          continue;
        }
        _logger.info('$prLabel: matched provider ${provider.name}');

        final patResult = await _loadPat();
        if (patResult.isLeft) {
          _logger.warning('$prLabel: PAT read error: ${patResult.left.message}');
          errors++;
          continue;
        }
        final pat = patResult.right;
        if (pat == null || pat.trim().isEmpty) {
          _logger.warning('$prLabel: PAT is empty, skipping');
          errors++;
          continue;
        }

        _logger.info('$prLabel: fetching provider info...');
        final syncResult = await _syncProvider(pr, provider, pat);
        if (syncResult.isLeft) {
          _logger.warning('$prLabel: sync failed: ${syncResult.left.message}');
          errors++;
          continue;
        }
        _logger.info('$prLabel: provider info updated successfully');

        final updatedStatus = await _loadProviderStatus(pr.id);
        if (updatedStatus == 'completed') {
          _logger.info('$prLabel: status is completed, checking environments...');
          final lastCommit = await _loadLastCommit(pr.id);
          final workingDir = await _resolveWorkingDirectory(pr);
          await _syncEnvironments(pr.id, lastCommit, workingDir);
        } else {
          _logger.info('$prLabel: status=$updatedStatus, skipping environment check');
        }

        if (pr.jiraTicket != null && pr.jiraTicket!.trim().isNotEmpty) {
          _logger.info('$prLabel: syncing ticket status...');
          await _syncTicketStatus(pr.id, pr.jiraTicket!);
        }

        ok++;
      }
    } finally {
      _isSyncRunning = false;
      final elapsed = stopwatch.elapsedMilliseconds;
      _logger.info(
        'PR sync finished: $ok OK, $errors errors, $skipped skipped in ${elapsed}ms',
      );
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
    final prLabel = 'PR #${pr.id}';
    _logger.info('$prLabel: calling ${provider.name} API...');

    String? remoteUrl;
    if (pr.projectAlias.trim().isNotEmpty) {
      final projectResult = await _projectRepository.getByAlias(pr.projectAlias);
      if (projectResult.isRight && projectResult.right != null) {
        final path = projectResult.right!.path;
        final remoteResult = await _gitClient.getRemoteUrl(workingDirectory: path);
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
      '$prLabel: provider response -> status=${info.status}, commitSha=${info.lastCommitSha}',
    );
    final updateResult = await _repository.updateProviderInfo(
      id: pr.id,
      provider: info.provider,
      providerPrId: info.pullRequestId,
      providerStatus: info.status,
      lastCommitSha: info.lastCommitSha,
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
    String? workingDirectory,
  ) async {
    if (lastCommitSha == null || lastCommitSha.trim().isEmpty) {
      _logger.info('PR #$prId: no commit SHA, skipping environment check');
      return;
    }
    if (workingDirectory == null || workingDirectory.trim().isEmpty) {
      _logger.warning('PR #$prId: missing working directory for git command');
      return;
    }
    _logger.info('PR #$prId: checking branches containing $lastCommitSha in $workingDirectory');
    final branchesResult = await _gitClient.branchesContainingCommit(
      lastCommitSha,
      workingDirectory: workingDirectory,
    );
    if (branchesResult.isLeft) {
      _logger.warning('PR #$prId: git branch-contains failed: ${branchesResult.left.message}');
      return;
    }
    final branches = branchesResult.right;

    final envResult = await _envMappingRepository.getAll();
    List<EnvironmentMapping> mappings;
    if (envResult.isLeft) {
      _logger.warning('PR #$prId: failed to load env mappings, using defaults');
      mappings = _defaultMappings();
    } else {
      mappings = envResult.right;
    }
    _logger.info(
      'PR #$prId: loaded ${mappings.length} env mapping(s)',
    );
    if (mappings.isNotEmpty) {
      for (final m in mappings) {
        _logger.info(
          '  env#${m.id}: name="${m.environmentName}", pattern="$m.branchPattern"',
        );
      }
    }

    _logger.info('PR #$prId: branches: $branches');
    final matchedIds = _resolveMatchedMappingIds(branches, mappings);
    _logger.info('PR #$prId: matched env mapping ids: $matchedIds');
    await _repository.setEnvFlags(prId, matchedIds);
  }

  Future<void> _syncTicketStatus(int prId, String ticketUrl) async {
    final provider = _ticketProviderRegistry.match(ticketUrl);
    if (provider == null) {
      _logger.warning('PR #$prId: no ticket provider supports URL $ticketUrl');
      return;
    }
    _logger.info('PR #$prId: matched ticket provider ${provider.name}');

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
      _logger.warning('PR #$prId: PAT not configured for ${provider.name}, skipping ticket sync');
      return;
    }

    final infoResult = await provider.fetchTicketInfo(
      url: ticketUrl,
      pat: pat,
      instanceUrl: instanceUrl,
      email: email,
    );
    if (infoResult.isLeft) {
      _logger.warning('PR #$prId: ticket sync failed: ${infoResult.left.message}');
      return;
    }

    final info = infoResult.right;
    _logger.info('PR #$prId: ticket status -> ${info.status} (closed=${info.isClosed})');
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
    return normalized.endsWith('/$pattern') || normalized == pattern;
  }
}
