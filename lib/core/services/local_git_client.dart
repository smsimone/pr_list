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
      final result = await Process.run(
        'git',
        ['branch', '-r', '--contains', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final output = result.stdout.toString();
      final branches = output
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
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
    final branchName = branch.trim();
    try {
      final result = await Process.run(
        'git',
        ['branch', '-a', '--list', branchName, '*/$branchName'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final output = result.stdout.toString();
      final rawBranches = output
          .split('\n')
          .map((line) => line.trim())
          .where((line) => line.isNotEmpty)
          .toList();
      final normalizedBranches = rawBranches
          .map(_normalizeBranchName)
          .where((line) => line.isNotEmpty)
          .toSet();
      final normalizedInput = _normalizeBranchName(branchName);
      final exists =
          normalizedBranches.contains(normalizedInput) ||
          normalizedBranches.any(
            (item) => item.endsWith('/$branchName'),
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
      final result = await Process.run(
        'git',
        ['remote'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final output = result.stdout.toString();
      final hasConfiguredRemote = output
          .split('\n')
          .map((line) => line.trim())
          .any((line) => line.isNotEmpty);
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
        final fetchResult = await Process.run(
          'git',
          ['fetch', '--prune', 'origin'],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        if (fetchResult.exitCode != 0) {
          return Either.left(
            Failure(message: 'git fetch failed', cause: fetchResult.stderr),
          );
        }
      }

      final result = await Process.run(
        'git',
        ['branch', '-a'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        return Either.left(
          Failure(message: 'git branch -a failed', cause: result.stderr),
        );
      }

      final output = result.stdout.toString();
      final branches = output
          .split('\n')
          .map((line) => _normalizeBranchName(line))
          .where((line) => line.isNotEmpty)
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
