import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

abstract class GitClient {
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
  });

  /// Checks which remote branches contain a commit with the same [patchId]
  /// as the given [commitSha]. This detects cherry-picked commits.
  ///
  /// If [onlyBranches] is provided, only those branches are checked.
  /// [baseRef] is an optional branch ref used to compute a merge-base range
  /// (e.g. `origin/develop`) so only commits unique to each checked branch
  /// are examined — dramatically faster for branches with long history.
  Future<Either<Failure, List<String>>> branchesContainingPatchId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? baseRef,
  });

  Future<Either<Failure, bool>> branchExists(
    String branch, {
    required String workingDirectory,
  });

  Future<Either<Failure, bool>> hasRemote({required String workingDirectory});

  Future<Either<Failure, List<String>>> listBranches({
    required String workingDirectory,
    bool fetch = false,
  });

  Future<Either<Failure, String>> getRemoteUrl({
    required String workingDirectory,
  });
}
