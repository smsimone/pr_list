import 'dart:io';

import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class LocalGitClient implements GitClient {
  @override
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
  }) async {
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    try {
      final ProcessResult result = await Process.run(
        'git',
        <String>['branch', '-r', '--contains', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
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

  @override
  Future<Either<Failure, bool>> branchExists(
    String branch, {
    required String workingDirectory,
  }) async {
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    final String branchName = branch.trim();
    try {
      final ProcessResult result = await Process.run(
        'git',
        <String>['branch', '-a', '--list', branchName, '*/$branchName'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final String output = result.stdout.toString();
      final List<String> rawBranches = output
          .split('\n')
          .map((String line) => line.trim())
          .where((String line) => line.isNotEmpty)
          .toList();
      final Set<String> normalizedBranches = rawBranches
          .map(_normalizeBranchName)
          .where((String line) => line.isNotEmpty)
          .toSet();
      final String normalizedInput = _normalizeBranchName(branchName);
      final bool exists =
          normalizedBranches.contains(normalizedInput) ||
          normalizedBranches.any(
            (String item) => item.endsWith('/$branchName'),
          );
      return Either.right(exists);
    } catch (err) {
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, bool>> hasRemote({
    required String workingDirectory,
  }) async {
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    try {
      final ProcessResult result = await Process.run(
        'git',
        <String>['remote'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final String output = result.stdout.toString();
      final bool hasConfiguredRemote = output
          .split('\n')
          .map((String line) => line.trim())
          .any((String line) => line.isNotEmpty);
      return Either.right(hasConfiguredRemote);
    } catch (err) {
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, List<String>>> listBranches({
    required String workingDirectory,
    bool fetch = false,
  }) async {
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    try {
      if (fetch) {
        final ProcessResult fetchResult = await Process.run(
          'git',
          <String>['fetch', '--prune', 'origin'],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        if (fetchResult.exitCode != 0) {
          return Either.left(
            Failure(message: 'git fetch failed', cause: fetchResult.stderr),
          );
        }
      }

      final ProcessResult result = await Process.run(
        'git',
        <String>['branch', '-a'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git branch -a failed', cause: result.stderr),
        );
      }

      final String output = result.stdout.toString();
      final List<String> branches = output
          .split('\n')
          .map((String line) => _normalizeBranchName(line))
          .where((String line) => line.isNotEmpty)
          .toSet()
          .toList();
      return Either.right(branches);
    } catch (err) {
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  String _normalizeBranchName(String branch) {
    String normalized = branch.replaceFirst('*', '').trim();
    normalized = normalized.replaceFirst('remotes/', '');
    if (normalized.startsWith('origin/HEAD')) {
      return '';
    }
    if (normalized.contains(' -> ')) {
      normalized = normalized.split(' -> ').first.trim();
    }
    return normalized;
  }
}
