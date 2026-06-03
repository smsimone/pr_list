import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class LocalGitClient implements GitClient {
  final _logger = Logger('LocalGitClient');

  String _logPrefix(String? prId) =>
      prId != null ? '[PR#$prId] ' : '';

  @override
  Future<Either<Failure, List<String>>> branchesContainingCommit(
    String commitSha, {
    required String workingDirectory,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    _logger.info('${p}git fetch --prune origin in $workingDirectory');
    try {
      final fetchResult = await Process.run(
        'git',
        ['fetch', '--prune', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (fetchResult.exitCode != 0) {
        _logger.warning('${p}git fetch exit ${fetchResult.exitCode}: ${fetchResult.stderr}');
        return Either.left(
          Failure(message: 'git fetch failed', cause: fetchResult.stderr),
        );
      }
      _logger.info('${p}git fetch completed (exit 0)');
    } catch (err) {
      _logger.severe('${p}git fetch error: $err');
      return Either.left(Failure(message: 'git fetch error', cause: err));
    }

    _logger.info('${p}git branch -r --contains $commitSha in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['branch', '-r', '--contains', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('${p}git exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('${p}git completed (exit 0): ${branches.length} branch(es)');
      return Either.right(branches);
    } catch (err) {
      _logger.severe('${p}git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, List<String>>> branchesContainingChangeId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );

    if (onlyBranches == null || onlyBranches.isEmpty) {
      return Either.right([]);
    }

    final msgResult = await Process.run(
      'git',
      ['log', '--format=%B', '-1', commitSha],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (msgResult.exitCode != 0) {
      return Either.left(
        Failure(message: 'git log failed', cause: msgResult.stderr),
      );
    }
    final fullMessage = msgResult.stdout.toString().trim();
    if (fullMessage.isEmpty) return Either.right([]);

    final changeIdMatch = RegExp(
      r'^Change-Id:\s*(I[a-zA-Z0-9]+)\s*$',
      multiLine: true,
      caseSensitive: false,
    ).firstMatch(fullMessage);
    final changeId = changeIdMatch?.group(1);

    final mergedPrMatch = RegExp(r'Merged PR\s+(\d+)', caseSensitive: false)
        .firstMatch(fullMessage);
    final mergedPrToken = mergedPrMatch != null
        ? 'Merged PR ${mergedPrMatch.group(1)}'
        : null;

    _logger.info(
      '$p change-id check for $commitSha: changeId=$changeId, '
      'mergedPr=$mergedPrToken, branches=$onlyBranches',
    );

    final patterns = <String>[
      if (changeId != null && changeId.trim().isNotEmpty) 'Change-Id: $changeId',
      ?mergedPrToken,
    ];

    if (patterns.isEmpty) {
      _logger.info('$p no Change-Id or Merged PR token found for $commitSha');
      return Either.right([]);
    }

    final results = <String>{};
    for (final branch in onlyBranches) {
      final branchRef = 'origin/$branch';
      for (final pattern in patterns) {
        try {
          final result = await Process.run(
            'git',
            [
              'log',
              '--format=%H',
              '--fixed-strings',
              '--grep',
              pattern,
              '-1',
              branchRef,
            ],
            workingDirectory: workingDirectory,
            runInShell: true,
          );
          if (result.exitCode == 0 &&
              result.stdout.toString().trim().isNotEmpty) {
            _logger.info(
              '$p change-id match for $branchRef with pattern "$pattern"',
            );
            results.add(branch);
            break;
          }
        } catch (err) {
          _logger.warning('$p change-id check failed for $branchRef: $err');
        }
      }
    }

    _logger.info(
      '$p change-id check for $commitSha -> ${results.length} branch(es): $results',
    );
    return Either.right(results.toList());
  }

  @override
  Future<Either<Failure, bool>> branchExists(
    String branch, {
    required String workingDirectory,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    final branchName = branch.trim();
    _logger.info('$p git branch -a --list $branchName in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['branch', '-a', '--list', branchName, '*/$branchName'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('$p git exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('$p git branch-exists($branchName) -> $exists');
      return Either.right(exists);
    } catch (err) {
      _logger.severe('$p git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, bool>> hasRemote({
    required String workingDirectory,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    _logger.info('$p git remote in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['remote'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('$p git remote exit ${result.exitCode}: ${result.stderr}');
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final output = result.stdout.toString();
      final hasConfiguredRemote = output
          .split('\n')
          .map((line) => line.trim())
          .any((line) => line.isNotEmpty);
      _logger.info('$p git remote -> hasRemote=$hasConfiguredRemote');
      return Either.right(hasConfiguredRemote);
    } catch (err) {
      _logger.severe('$p git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, String>> getRemoteUrl({
    required String workingDirectory,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    _logger.info('$p git remote get-url origin in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['remote', 'get-url', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('$p git remote get-url exit ${result.exitCode}: ${result.stderr}');
        return Either.left(
          Failure(message: 'git remote get-url failed', cause: result.stderr),
        );
      }
      final url = result.stdout.toString().trim();
      _logger.info('$p git remote get-url origin -> $url');
      return Either.right(url);
    } catch (err) {
      _logger.severe('$p git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, List<String>>> listBranches({
    required String workingDirectory,
    bool fetch = false,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    _logger.info('$p listBranches in $workingDirectory (fetch=$fetch)');
    try {
      if (fetch) {
        _logger.info('$p git fetch --prune origin in $workingDirectory');
        final fetchResult = await Process.run(
          'git',
          ['fetch', '--prune', 'origin'],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        if (fetchResult.exitCode != 0) {
          _logger.warning('$p git fetch exit ${fetchResult.exitCode}: ${fetchResult.stderr}');
          return Either.left(
            Failure(message: 'git fetch failed', cause: fetchResult.stderr),
          );
        }
        _logger.info('$p git fetch completed (exit 0)');
      }

      _logger.info('$p git branch -a in $workingDirectory');
      final result = await Process.run(
        'git',
        ['branch', '-a'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('$p git branch -a exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('$p git branch -a -> ${branches.length} branch(es)');
      return Either.right(branches);
    } catch (err) {
      _logger.severe('$p git command error: $err');
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
