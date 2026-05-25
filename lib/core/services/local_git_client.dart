import 'dart:convert';
import 'dart:io';

import 'package:logging/logging.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class LocalGitClient implements GitClient {
  final _logger = Logger('LocalGitClient');
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
    _logger.info('git fetch --prune origin in $workingDirectory');
    try {
      final fetchResult = await Process.run(
        'git',
        ['fetch', '--prune', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (fetchResult.exitCode != 0) {
        _logger.warning('git fetch exit ${fetchResult.exitCode}: ${fetchResult.stderr}');
        return Either.left(
          Failure(message: 'git fetch failed', cause: fetchResult.stderr),
        );
      }
      _logger.info('git fetch completed (exit 0)');
    } catch (err) {
      _logger.severe('git fetch error: $err');
      return Either.left(Failure(message: 'git fetch error', cause: err));
    }

    _logger.info('git branch -r --contains $commitSha in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['branch', '-r', '--contains', commitSha],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('git exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('git completed (exit 0): ${branches.length} branch(es)');
      return Either.right(branches);
    } catch (err) {
      _logger.severe('git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, List<String>>> branchesContainingPatchId(
    String commitSha, {
    required String workingDirectory,
    List<String>? onlyBranches,
    String? baseRef,
  }) async {
    assert(commitSha.trim().isNotEmpty, 'commitSha must not be empty');
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );

    if (onlyBranches == null || onlyBranches.isEmpty) {
      _logger.info('No branches to check for patch-id, skipping');
      return Either.right([]);
    }

    // Step 1: fast content-match for ALL branches in parallel
    // This detects ported changes regardless of workflow (cherry-pick, squash merge, etc.)
    _logger.info('content-match: checking $onlyBranches for $commitSha');
    final contentFutures = onlyBranches.map((branch) async {
      final branchRef = 'origin/$branch';
      final match = await _branchHasMatchingContent(
        branchRef, commitSha, workingDirectory,
      );
      _logger.info('content-match for $commitSha on $branchRef -> $match');
      return (branch, match);
    });
    final contentResults = await Future.wait(contentFutures.toList());

    final results = <String>{};
    for (final (branch, match) in contentResults) {
      if (match) results.add(branch);
    }

    // Step 2: for branches not found by content match, try patch-id + commit message
    final unmatched = onlyBranches
        .where((b) => !results.contains(b))
        .toList();

    if (unmatched.isNotEmpty) {
      _logger.info(
        'content-match unmatched branches: $unmatched, computing patch-id for $commitSha',
      );
      final patchId = await _computePatchId(commitSha, workingDirectory);
      if (patchId != null) {
        for (final branch in unmatched) {
          final branchRef = 'origin/$branch';
          final found = await _checkBranchForPatchIdSlow(
            patchId, branchRef, commitSha,
            baseRef: baseRef, workingDirectory: workingDirectory,
          );
          if (found) results.add(branch);
        }
      }
    }

    _logger.info(
      'patch-id check for $commitSha -> ${results.length} branch(es): $results',
    );
    return Either.right(results.toList());
  }

  /// Computes the patch-id for the given commit SHA.
  /// Returns null on failure.
  Future<String?> _computePatchId(
    String commitSha,
    String workingDirectory,
  ) async {
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
          'git show/patch-id failed for $commitSha (show exit $showExitCode, '
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
        _logger.warning('Empty patch-id for commit $commitSha');
        return null;
      }
      _logger.info('patch-id for $commitSha -> $patchId');
      return patchId;
    } catch (err) {
      _logger.severe('git patch-id error: $err');
      return null;
    }
  }

  /// Detects a cherry-picked commit by checking patch-id and commit message
  /// on [branchRef]. Content-match is NOT included here (it runs first, at
  /// the [branchesContainingPatchId] level). This is intentionally sequential
  /// per branch because the caller already paid the cost for the fast path.
  Future<bool> _checkBranchForPatchIdSlow(
    String targetPatchId,
    String branchRef,
    String commitSha, {
    String? baseRef,
    required String workingDirectory,
  }) async {
    final rangeRefFuture = _buildRangeRef(branchRef, baseRef, workingDirectory);

    final futures = <Future<bool>>[
      rangeRefFuture.then((rangeRef) async {
        try {
          _logger.info("Built range ref from $baseRef -> $rangeRef");
          return await _patchIdExistsInLog(rangeRef, targetPatchId, workingDirectory);
        } catch (err) {
          _logger.warning('patch-id check failed for $branchRef: $err');
          return false;
        }
      }),
      (() async {
        try {
          return await _cherryPickMessageExists(
            branchRef, commitSha, workingDirectory,
          );
        } catch (err) {
          _logger.warning('commit-message check failed for $branchRef: $err');
          return false;
        }
      })(),
    ];

    final results = await Future.wait(futures);
    return results.any((r) => r);
  }

  /// Builds a range expression like `<merge-base>..<branchRef>` to limit
  /// the log to commits unique to that branch. Falls back to last 100
  /// commits when no [baseRef] is available.
  Future<String> _buildRangeRef(
    String branchRef,
    String? baseRef,
    String workingDirectory,
  ) async {
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

  /// Checks whether any commit in [rangeRef] has a [targetPatchId].
  /// Processes commits one at a time (most recent first) via
  /// `git diff-tree -p -m <sha> | git patch-id`, stopping at the first match.
  /// `git diff-tree` is significantly faster than `git log -p` because it reads
  /// only tree objects without parsing commit metadata.
  Future<bool> _patchIdExistsInLog(
    String rangeRef,
    String targetPatchId,
    String workingDirectory,
  ) async {
    // Get commit SHA list in the range, most recent first
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

    // Process each commit individually — stop at first match
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
        // Skip commits that fail to diff
      }
    }
    return false;
  }

  /// Checks whether any commit on [branchRef] has a message containing
  /// `cherry picked from commit <commitSha>`.
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

  /// Checks whether all files introduced/changed by [commitSha] have the same
  /// blob hashes on [branchRef]. This detects ported changes from any workflow
  /// (cherry-pick, squash merge, rebase, manual application) as long as no
  /// subsequent modifications to the same files exist on the target branch.
  Future<bool> _branchHasMatchingContent(
    String branchRef,
    String commitSha,
    String workingDirectory,
  ) async {
    _logger.info('content-match: checking $commitSha on $branchRef');

    // Refresh remote refs so origin/* are up-to-date
    try {
      await Process.run(
        'git',
        ['fetch', '--prune', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
    } catch (_) {
      // Non-fatal; stale data is still acceptable
    }

    // Get the parent commit to compute the diff introduced by this commit
    final parentResult = await Process.run(
      'git',
      ['rev-parse', '$commitSha^1'],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (parentResult.exitCode != 0) return false;
    final parentSha = parentResult.stdout.toString().trim();

    // Get all files changed in this commit with their new blob hashes
    final diffResult = await Process.run(
      'git',
      ['diff-tree', '--no-commit-id', '-r', parentSha, commitSha],
      workingDirectory: workingDirectory,
      runInShell: true,
    );
    if (diffResult.exitCode != 0) return false;

    // Parse output: <old-mode> <new-mode> <old-blob> <new-blob> <status>\t<path>
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
      'content-match: checking ${filesToCheck.length} file(s) on $branchRef: ${filesToCheck.keys}',
    );

    // Get blob hashes for all changed files on the target branch in one call
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

    _logger.info('content-match: target blobs on $branchRef: $targetBlobs');

    for (final entry in filesToCheck.entries) {
      final targetBlob = targetBlobs[entry.key];
      final expectedBlob = entry.value;
      if (targetBlob == null) {
        _logger.info(
          'content-match: MISSING file "${entry.key}" on $branchRef',
        );
        return false;
      }
      if (targetBlob != expectedBlob) {
        _logger.info(
          'content-match: BLOB MISMATCH for "${entry.key}" on $branchRef '
          '(expected=$expectedBlob, got=$targetBlob)',
        );
        return false;
      }
    }

    _logger.info('content-match: ALL files match on $branchRef');
    return true;
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
    _logger.info('git branch -a --list $branchName in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['branch', '-a', '--list', branchName, '*/$branchName'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('git exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('git branch-exists($branchName) -> $exists');
      return Either.right(exists);
    } catch (err) {
      _logger.severe('git command error: $err');
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
    _logger.info('git remote in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['remote'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('git remote exit ${result.exitCode}: ${result.stderr}');
        return Either.left(
          Failure(message: 'git command failed', cause: result.stderr),
        );
      }
      final output = result.stdout.toString();
      final hasConfiguredRemote = output
          .split('\n')
          .map((line) => line.trim())
          .any((line) => line.isNotEmpty);
      _logger.info('git remote -> hasRemote=$hasConfiguredRemote');
      return Either.right(hasConfiguredRemote);
    } catch (err) {
      _logger.severe('git command error: $err');
      return Either.left(Failure(message: 'git command error', cause: err));
    }
  }

  @override
  Future<Either<Failure, String>> getRemoteUrl({
    required String workingDirectory,
  }) async {
    assert(
      workingDirectory.trim().isNotEmpty,
      'workingDirectory must not be empty',
    );
    _logger.info('git remote get-url origin in $workingDirectory');
    try {
      final result = await Process.run(
        'git',
        ['remote', 'get-url', 'origin'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('git remote get-url exit ${result.exitCode}: ${result.stderr}');
        return Either.left(
          Failure(message: 'git remote get-url failed', cause: result.stderr),
        );
      }
      final url = result.stdout.toString().trim();
      _logger.info('git remote get-url origin -> $url');
      return Either.right(url);
    } catch (err) {
      _logger.severe('git command error: $err');
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
    _logger.info('listBranches in $workingDirectory (fetch=$fetch)');
    try {
      if (fetch) {
        _logger.info('git fetch --prune origin in $workingDirectory');
        final fetchResult = await Process.run(
          'git',
          ['fetch', '--prune', 'origin'],
          workingDirectory: workingDirectory,
          runInShell: true,
        );
        if (fetchResult.exitCode != 0) {
          _logger.warning('git fetch exit ${fetchResult.exitCode}: ${fetchResult.stderr}');
          return Either.left(
            Failure(message: 'git fetch failed', cause: fetchResult.stderr),
          );
        }
        _logger.info('git fetch completed (exit 0)');
      }

      _logger.info('git branch -a in $workingDirectory');
      final result = await Process.run(
        'git',
        ['branch', '-a'],
        workingDirectory: workingDirectory,
        runInShell: true,
      );
      if (result.exitCode != 0) {
        _logger.warning('git branch -a exit ${result.exitCode}: ${result.stderr}');
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
      _logger.info('git branch -a -> ${branches.length} branch(es)');
      return Either.right(branches);
    } catch (err) {
      _logger.severe('git command error: $err');
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
