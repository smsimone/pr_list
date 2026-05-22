import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

abstract class GitClient {
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
  });

  Future<Either<Failure, bool>> branchExists(
    String branch, {
    required String workingDirectory,
  });

  Future<Either<Failure, bool>> hasRemote({required String workingDirectory});
}
