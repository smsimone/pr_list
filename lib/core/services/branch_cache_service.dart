import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class BranchCacheService {
  final GitClient _gitClient;
  final Map<String, List<String>> _cache = {};
  final Map<String, Future<void>> _pendingRefreshes = {};

  BranchCacheService(this._gitClient);

  Future<Either<Failure, List<String>>> getBranches(
    String projectPath, {
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _cache.containsKey(projectPath)) {
      _refreshInBackground(projectPath);
      return Either.right(List<String>.from(_cache[projectPath]!));
    }

    final Either<Failure, List<String>> result = await _gitClient.listBranches(
      workingDirectory: projectPath,
      fetch: true,
    );

    if (result.isRight) {
      _cache[projectPath] = List<String>.from(result.right);
    }

    return result;
  }

  void _refreshInBackground(String projectPath) {
    if (_pendingRefreshes.containsKey(projectPath)) return;

    _pendingRefreshes[projectPath] = _doRefresh(projectPath).then((_) {
      _pendingRefreshes.remove(projectPath);
    });
  }

  Future<void> _doRefresh(String projectPath) async {
    final Either<Failure, List<String>> result = await _gitClient.listBranches(
      workingDirectory: projectPath,
      fetch: true,
    );
    if (result.isRight) {
      _cache[projectPath] = List<String>.from(result.right);
    }
  }

  void invalidate(String projectPath) {
    _cache.remove(projectPath);
    _pendingRefreshes.remove(projectPath);
  }
}
