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

  /// Checks which remote branches contain a commit whose message matches
  /// the message of [commitSha] (via `git log --grep`). This detects squash
  /// merges and rebased commits where the original commit message is preserved.
  ///
  /// If [onlyBranches] is provided, only those branches are checked.
  /// Extracts both the subject line and any issue ID (e.g. PRJ-1234) from
  /// the original commit message and tries each as a grep pattern.
  Future<Either<Failure, List<String>>> branchesContainingMessage(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
  });

  /// Checks which remote branches contain a commit that introduced or removed
  /// a code string matching the diff of [commitSha] (via `git log -S` pickaxe).
  /// This is the last-resort strategy for detecting cherry-picks that were
  /// modified after porting (different SHA, different patch-id, different message).
  ///
  /// If [onlyBranches] is provided, only those branches are checked.
  /// If [searchStrings] is provided, those strings are used directly; otherwise
  /// unique strings are auto-extracted from the commit diff (quoted strings and
  /// long identifiers).
  Future<Either<Failure, List<String>>> branchesContainingString(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    List<String>? searchStrings,
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
