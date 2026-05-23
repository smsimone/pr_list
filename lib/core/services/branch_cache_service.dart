import 'package:logging/logging.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class BranchCacheService {
  final _logger = Logger('BranchCacheService');
  final GitClient _gitClient;
  final Map<String, List<String>> _cache = {};
  final Map<String, Future<void>> _pendingRefreshes = {};

  BranchCacheService(this._gitClient);

  Future<Either<Failure, List<String>>> getBranches(
    String projectPath, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(projectPath)) {
      _logger.info('Cache hit for $projectPath (${_cache[projectPath]!.length} branches)');
      _refreshInBackground(projectPath);
      return Either.right(List<String>.from(_cache[projectPath]!));
    }

    _logger.info('Cache miss for $projectPath, fetching...');
    final Either<Failure, List<String>> result = await _gitClient.listBranches(
      workingDirectory: projectPath,
      fetch: true,
    );

    if (result.isRight) {
      _cache[projectPath] = List<String>.from(result.right);
      _logger.info('Cached ${result.right.length} branches for $projectPath');
    } else {
      _logger.warning('Failed to fetch branches for $projectPath: ${result.left.message}');
    }

    return result;
  }

  void _refreshInBackground(String projectPath) {
    if (_pendingRefreshes.containsKey(projectPath)) {
      _logger.info('Background refresh already pending for $projectPath');
      return;
    }

    _logger.info('Starting background refresh for $projectPath');
    _pendingRefreshes[projectPath] = _doRefresh(projectPath).then((_) {
      _pendingRefreshes.remove(projectPath);
      _logger.info('Background refresh completed for $projectPath');
    });
  }

  Future<void> _doRefresh(String projectPath) async {
    final result = await _gitClient.listBranches(
      workingDirectory: projectPath,
      fetch: true,
    );
    if (result.isRight) {
      _cache[projectPath] = List<String>.from(result.right);
      _logger.info('Background refresh: cached ${result.right.length} branches for $projectPath');
    } else {
      _logger.warning('Background refresh failed for $projectPath: ${result.left.message}');
    }
  }

  void invalidate(String projectPath) {
    _logger.info('Invalidated cache for $projectPath');
    _cache.remove(projectPath);
    _pendingRefreshes.remove(projectPath);
  }
}
