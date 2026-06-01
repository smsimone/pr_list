import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

abstract class GitClient {
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
    String? prId,
  });

  Future<Either<Failure, List<String>>> branchesContainingPatchId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? baseRef,
    String? prId,
  });

  Future<Either<Failure, List<String>>> branchesContainingMessage(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? prId,
  });

  Future<Either<Failure, List<String>>> branchesContainingString(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    List<String>? searchStrings,
    String? prId,
  });

  Future<Either<Failure, bool>> branchExists(
    String branch, {
    required String workingDirectory,
    String? prId,
  });

  Future<Either<Failure, bool>> hasRemote({
    required String workingDirectory,
    String? prId,
  });

  Future<Either<Failure, List<String>>> listBranches({
    required String workingDirectory,
    bool fetch = false,
    String? prId,
  });

  Future<Either<Failure, String>> getRemoteUrl({
    required String workingDirectory,
    String? prId,
  });
}
