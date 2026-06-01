import 'dart:convert';
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
  Future<Either<Failure, List<String>>> branchesContainingPatchId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? baseRef,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );

    if (onlyBranches == null || onlyBranches.isEmpty) {
      _logger.info('${p}No branches to check for patch-id, skipping');
      return Either.right([]);
    }

    _logger.info('${p}content-match: checking $onlyBranches for $commitSha');
    final contentFutures = onlyBranches.map((branch) async {
      final branchRef = 'origin/$branch';
      final match = await _branchHasMatchingContent(
        branchRef, commitSha, workingDirectory, prId: prId,
      );
      _logger.info('${p}content-match for $commitSha on $branchRef -> $match');
      return (branch, match);
    });
    final contentResults = await Future.wait(contentFutures.toList());

    final results = <String>{};
    for (final (branch, match) in contentResults) {
      if (match) results.add(branch);
    }

    final unmatched = onlyBranches
        .where((b) => !results.contains(b))
        .toList();

    if (unmatched.isNotEmpty) {
      _logger.info(
        '${p}content-match unmatched branches: $unmatched, computing patch-id for $commitSha',
      );
      final patchId = await _computePatchId(commitSha, workingDirectory, prId: prId);
      if (patchId != null) {
        for (final branch in unmatched) {
          final branchRef = 'origin/$branch';
          final found = await _checkBranchForPatchIdSlow(
            patchId, branchRef, commitSha,
            baseRef: baseRef, workingDirectory: workingDirectory, prId: prId,
          );
          if (found) results.add(branch);
        }
      }
    }

    _logger.info(
      '${p}patch-id check for $commitSha -> ${results.length} branch(es): $results',
    );
    return Either.right(results.toList());
  }

  @override
  Future<Either<Failure, List<String>>> branchesContainingMessage(
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

    final subject = fullMessage.split('\n').first.trim();
    final issueIdMatch = RegExp(r'[A-Z][A-Z0-9]+-\d+').firstMatch(subject);
    final issueId = issueIdMatch?.group(0);

    _logger.info(
      '$p message-grep for $commitSha: subject="$subject", issueId=$issueId'
      ', branches=$onlyBranches',
    );

    final patterns = <String>[
      ?issueId,
      subject,
    ];

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
              '$p message-grep match for $branchRef with pattern "$pattern"',
            );
            results.add(branch);
            break;
          }
        } catch (err) {
          _logger.warning('$p message-grep failed for $branchRef: $err');
        }
      }
    }

    _logger.info(
      '$p message-grep for $commitSha -> ${results.length} branch(es): $results',
    );
    return Either.right(results.toList());
  }

  @override
  Future<Either<Failure, List<String>>> branchesContainingString(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    List<String>? searchStrings,
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

    final strings = searchStrings ??
        await _extractSearchStrings(commitSha, workingDirectory, prId: prId);
    if (strings.isEmpty) {
      _logger.info('$p no search strings for $commitSha, skipping pickaxe');
      return Either.right([]);
    }

    _logger.info(
      '$p pickaxe for $commitSha: ${strings.length} string(s) on '
      '${onlyBranches.length} branch(es): $strings',
    );

    final results = <String>{};
    for (final branch in onlyBranches) {
      final branchRef = 'origin/$branch';
      for (final searchString in strings) {
        try {
          final result = await Process.run(
            'git',
            [
              'log',
              '--format=%H',
              '-S',
              searchString,
              '-1',
              branchRef,
            ],
            workingDirectory: workingDirectory,
            runInShell: true,
          );
          if (result.exitCode == 0 &&
              result.stdout.toString().trim().isNotEmpty) {
            _logger.info(
              '$p pickaxe match for $branchRef with "$searchString"',
            );
            results.add(branch);
            break;
          }
        } catch (err) {
          _logger.warning('$p pickaxe failed for $branchRef: $err');
        }
      }
    }

    _logger.info(
      '$p pickaxe for $commitSha -> ${results.length} branch(es): $results',
    );
    return Either.right(results.toList());
  }

  Future<List<String>> _extractSearchStrings(
    String commitSha,
    String workingDirectory, {
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    try {
      final result = await Process.run(
        'git',
        ['diff-tree', '--no-commit-id', '-p', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) return [];

      final lines = result.stdout.toString().split('\n');
      final strings = <String>{};

      for (final line in lines) {
        if (!line.startsWith('+')) continue;
        if (line.startsWith('+++') || line.startsWith('---')) continue;
        if (line.length <= 1) continue;

        final content = line.substring(1);

        for (final m
            in RegExp(r'"([^"]*)"').allMatches(content)) {
          final q = m.group(1)!.trim();
          if (q.length >= 10) strings.add(q);
        }

        for (final m
            in RegExp(r"'([^']*)'").allMatches(content)) {
          final q = m.group(1)!.trim();
          if (q.length >= 10) strings.add(q);
        }
      }

      if (strings.isEmpty) {
        for (final line in lines) {
          if (!line.startsWith('+')) continue;
          if (line.startsWith('+++') || line.startsWith('---')) continue;
          if (line.length <= 1) continue;

          final trimmed = line.substring(1).trim();
          if (trimmed.length < 30) continue;
          if (trimmed.startsWith('//') || trimmed.startsWith('*')) continue;

          final identifiers = trimmed
              .split(RegExp(r'\s+|[,;(){}<>\[\].=+*/&|!~^%]'))
              .where((w) => w.length >= 8 && !RegExp(r'^\d+$').hasMatch(w))
              .toList();
          identifiers.sort((a, b) => b.length.compareTo(a.length));
          if (identifiers.isNotEmpty) strings.add(identifiers.first);
        }
      }

      final resultList = strings.toList();
      resultList.sort((a, b) => b.length.compareTo(a.length));
      return resultList.take(3).toList();
    } catch (err) {
      _logger.warning('$p extractSearchStrings error: $err');
      return [];
    }
  }

  Future<String?> _computePatchId(
    String commitSha,
    String workingDirectory, {
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    try {
      final showProcess = await Process.start(
        'git',
        ['show', '-m', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      final patchIdProcess = await Process.start(
        'git',
        ['patch-id'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      await showProcess.stdout.pipe(patchIdProcess.stdin);
      final patchIdOutput =
          await patchIdProcess.stdout.transform(utf8.decoder).join();
      final showExitCode = await showProcess.exitCode;
      final patchIdExitCode = await patchIdProcess.exitCode;

      if (showExitCode != 0 || patchIdExitCode != 0) {
        _logger.warning(
          '$p git show/patch-id failed for $commitSha (show exit $showExitCode, '
          'patch-id exit $patchIdExitCode)',
        );
        return null;
      }

      final firstLine = patchIdOutput
          .trim()
          .split('\n')
          .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '');
      final patchId = firstLine.split(' ').first;
      if (patchId.isEmpty) {
        _logger.warning('$p Empty patch-id for commit $commitSha');
        return null;
      }
      _logger.info('$p patch-id for $commitSha -> $patchId');
      return patchId;
    } catch (err) {
      _logger.severe('$p git patch-id error: $err');
      return null;
    }
  }

  Future<bool> _checkBranchForPatchIdSlow(
    String targetPatchId,
    String branchRef,
    String commitSha, {
    String? baseRef,
    required String workingDirectory,
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    final rangeRefFuture = _buildRangeRef(branchRef, baseRef, workingDirectory, prId: prId);

    final futures = <Future<bool>>[
      rangeRefFuture.then((rangeRef) async {
        try {
          _logger.info("$p Built range ref from $baseRef -> $rangeRef");
          return await _patchIdExistsInLog(rangeRef, targetPatchId, workingDirectory);
        } catch (err) {
          _logger.warning('$p patch-id check failed for $branchRef: $err');
          return false;
        }
      }),
      (() async {
        try {
          return await _cherryPickMessageExists(
            branchRef, commitSha, workingDirectory,
          );
        } catch (err) {
          _logger.warning('$p commit-message check failed for $branchRef: $err');
          return false;
        }
      })(),
    ];

    final results = await Future.wait(futures);
    return results.any((r) => r);
  }

  Future<String> _buildRangeRef(
    String branchRef,
    String? baseRef,
    String workingDirectory, {
    String? prId,
  }) async {
    if (baseRef == null) {
      return '-100 $branchRef';
    }
    try {
      final mergeBaseResult = await Process.run(
        'git',
        ['merge-base', baseRef, branchRef],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (mergeBaseResult.exitCode == 0) {
        final mergeBase = mergeBaseResult.stdout.toString().trim();
        if (mergeBase.isNotEmpty) {
          return '$mergeBase..$branchRef';
        }
      }
    } catch (_) {}
    return '-100 $branchRef';
  }

  Future<bool> _patchIdExistsInLog(
    String rangeRef,
    String targetPatchId,
    String workingDirectory,
  ) async {
    final revListResult = await Process.run(
      'git',
      ['rev-list'] + rangeRef.split(' '),
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (revListResult.exitCode != 0) return false;

    final shas = revListResult.stdout
        .toString()
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    for (final sha in shas) {
      try {
        final diffProcess = await Process.start(
          'git',
          ['diff-tree', '-p', '-m', sha],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        final patchIdProcess = await Process.start(
          'git',
          ['patch-id'],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        await diffProcess.stdout.pipe(patchIdProcess.stdin);
        final output =
            await patchIdProcess.stdout.transform(utf8.decoder).join();
        await Future.wait([diffProcess.exitCode, patchIdProcess.exitCode]);

        if (output.contains(targetPatchId)) return true;
      } catch (_) {
      }
    }
    return false;
  }

  Future<bool> _cherryPickMessageExists(
    String branchRef,
    String commitSha,
    String workingDirectory,
  ) async {
    final grepPattern = 'cherry picked from commit $commitSha';
    final result = await Process.run(
      'git',
      [
        'log',
        '--format=%H',
        '--fixed-strings',
        '--grep',
        grepPattern,
        '-1',
        branchRef,
      ],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    return result.exitCode == 0 && result.stdout.toString().trim().isNotEmpty;
  }

  Future<bool> _branchHasMatchingContent(
    String branchRef,
    String commitSha,
    String workingDirectory, {
    String? prId,
  }) async {
    final p = _logPrefix(prId);
    _logger.info('$p content-match: checking $commitSha on $branchRef');

    try {
      await Process.run(
        'git',
        ['fetch', '--prune', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
    } catch (_) {
    }

    final parentResult = await Process.run(
      'git',
      ['rev-parse', '$commitSha^1'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (parentResult.exitCode != 0) return false;
    final parentSha = parentResult.stdout.toString().trim();

    final diffResult = await Process.run(
      'git',
      ['diff-tree', '--no-commit-id', '-r', parentSha, commitSha],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (diffResult.exitCode != 0) return false;

    final filesToCheck = <String, String>{};
    for (final line in diffResult.stdout.toString().split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final parts = l.split('\t');
      if (parts.length < 2) continue;
      final path = parts[1].trim();
      final meta = parts[0].split(' ');
      if (meta.length < 4) continue;
      final newBlob = meta[3];
      final status = meta.length > 4 ? meta[4] : '';
      if (status == 'D' ||
          newBlob == '0000000000000000000000000000000000000000') {
        continue;
      }
      filesToCheck[path] = newBlob;
    }

    if (filesToCheck.isEmpty) return false;

    _logger.info(
      '$p content-match: checking ${filesToCheck.length} file(s) on $branchRef: ${filesToCheck.keys}',
    );

    final lsResult = await Process.run(
      'git',
      ['ls-tree', '-r', branchRef] + filesToCheck.keys.toList(),
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (lsResult.exitCode != 0) return false;

    final targetBlobs = <String, String>{};
    for (final line in lsResult.stdout.toString().split('\n')) {
      final l = line.trim();
      if (l.isEmpty) continue;
      final parts = l.split('\t');
      if (parts.length < 2) continue;
      final path = parts[1].trim();
      final meta = parts[0].split(' ');
      if (meta.length < 3) continue;
      targetBlobs[path] = meta[2];
    }

    _logger.info('$p content-match: target blobs on $branchRef: $targetBlobs');

    for (final entry in filesToCheck.entries) {
      final targetBlob = targetBlobs[entry.key];
      final expectedBlob = entry.value;
      if (targetBlob == null) {
        _logger.info(
          '$p content-match: MISSING file "${entry.key}" on $branchRef',
        );
        return false;
      }
      if (targetBlob != expectedBlob) {
        _logger.info(
          '$p content-match: BLOB MISMATCH for "${entry.key}" on $branchRef '
          '(expected=$expectedBlob, got=$targetBlob)',
        );
        return false;
      }
    }

    _logger.info('$p content-match: ALL files match on $branchRef');
    return true;
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
