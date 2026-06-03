import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

abstract class GitClient {
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
    String? prId,
  });

  Future<Either<Failure, List<String>>> branchesContainingChangeId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
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
