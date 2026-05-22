import 'dart:io';

import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class LocalGitClient implements GitClient {
  @override
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha,
  ) async {
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    try {
      final ProcessResult result = await Process.run(
        'git',
        <String>['branch', '-r', '--contains', commitSha],
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(
            message: 'git command failed',
            cause: result.stderr,
          ),
        );
      }
      final String output = result.stdout.toString();
      final List<String> branches = output
          .split('\n')
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList();
      return Either.right(branches);
    } catch (err) {
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }
}
