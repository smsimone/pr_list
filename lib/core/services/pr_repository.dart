import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class PrRepository {
  final _logger = Logger('PrRepository');
  final AppDatabase _db;

  PrRepository(this._db);

  Stream<List<PullRequest>> watchAll() {
    return _db.select(_db.pullRequests).watch();
  }

  Future<Either<Failure, PullRequest?>> getById(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      final query = _db.select(_db.pullRequests)
        ..where((tbl) => tbl.id.equals(id));
      final pr = await query.getSingleOrNull();
      return Either.right(pr);
    } catch (err) {
      _logger.warning('getById($id) failed: $err');
      return Either.left(Failure(message: 'Load PR failed', cause: err));
    }
  }

  Future<Either<Failure, int>> create({
    required String projectAlias,
    String? jiraTicket,
    String? prLink,
    String? provider,
    String? providerPrId,
  }) async {
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    final now = DateTime.now();
    try {
      final id = await _db
          .into(_db.pullRequests)
          .insert(
            PullRequestsCompanion.insert(
              projectAlias: projectAlias,
              jiraTicket: Value(jiraTicket),
              prLink: Value(prLink),
              provider: Value(provider),
              providerPrId: Value(providerPrId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      _logger.info('PR #$id created @ $projectAlias');
      return Either.right(id);
    } catch (err) {
      _logger.severe('Create PR failed: $err');
      return Either.left(Failure(message: 'Create PR failed', cause: err));
    }
  }

  Future<Either<Failure, void>> updatePr({
    required int id,
    required String projectAlias,
    String? jiraTicket,
    String? prLink,
    required bool isTicketClosed,
    String? provider,
    String? providerPrId,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    try {
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          projectAlias: Value(projectAlias),
          jiraTicket: Value(jiraTicket),
          prLink: Value(prLink),
          isTicketClosed: Value(isTicketClosed),
          provider: Value(provider),
          providerPrId: Value(providerPrId),
          updatedAt: Value(DateTime.now()),
        ),
      );
      _logger.info('PR #$id updated');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Update PR #$id failed: $err');
      return Either.left(Failure(message: 'Update PR failed', cause: err));
    }
  }

  Future<Either<Failure, void>> updateProviderInfo({
    required int id,
    required String provider,
    required String providerPrId,
    required String providerStatus,
    required String lastCommitSha,
    String? lastMergeCommitSha,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(provider.trim().isNotEmpty, 'provider must not be empty');
    assert(providerPrId.trim().isNotEmpty, 'providerPrId must not be empty');
    assert(
      providerStatus.trim().isNotEmpty,
      'providerStatus must not be empty',
    );
    assert(lastCommitSha.trim().isNotEmpty, 'lastCommitSha must not be empty');
    try {
      _logger.info(
        'Updating provider info for PR #$id: status=$providerStatus, '
        'sha=$lastCommitSha, mergeSha=${lastMergeCommitSha ?? '(none)'}',
      );
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          provider: Value(provider),
          providerPrId: Value(providerPrId),
          providerStatus: Value(providerStatus),
          lastCommitSha: Value(lastCommitSha),
          lastMergeCommitSha: Value(lastMergeCommitSha),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Update provider info for PR #$id failed: $err');
      return Either.left(
        Failure(message: 'Update provider failed', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> updateTicketStatus({
    required int id,
    required String ticketStatus,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(ticketStatus.trim().isNotEmpty, 'ticketStatus must not be empty');
    try {
      _logger.info('Updating ticket status for PR #$id: status=$ticketStatus');
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          ticketStatus: Value(ticketStatus),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Update ticket status for PR #$id failed: $err');
      return Either.left(
        Failure(message: 'Update ticket status failed', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> setEnvFlags(
    int prId,
    List<int> envMappingIds,
  ) async {
    assert(prId > 0, 'prId must be greater than 0');
    try {
      await _db.batch((batch) {
        batch.deleteWhere(
          _db.prEnvFlags,
          (t) => t.prId.equals(prId),
        );
        for (final mappingId in envMappingIds) {
          batch.insert(
            _db.prEnvFlags,
            PrEnvFlagsCompanion.insert(
              prId: prId,
              envMappingId: mappingId,
            ),
          );
        }
      });
      return const Either.right(null);
    } catch (err) {
      _logger.severe('setEnvFlags for PR #$prId failed: $err');
      return Either.left(
        Failure(message: 'Set environment flags failed', cause: err),
      );
    }
  }

  Future<Either<Failure, Map<int, List<int>>>> getAllEnvFlags() async {
    try {
      final rows = await _db.select(_db.prEnvFlags).get();
      final map = <int, List<int>>{};
      for (final row in rows) {
        map.putIfAbsent(row.prId, () => []).add(row.envMappingId);
      }
      return Either.right(map);
    } catch (err) {
      _logger.severe('getAllEnvFlags failed: $err');
      return Either.left(
        Failure(message: 'Load environment flags failed', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> delete(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      _logger.info('Deleting PR #$id');
      await _db.batch((batch) {
        batch.deleteWhere(
          _db.prEnvFlags,
          (t) => t.prId.equals(id),
        );
        batch.deleteWhere(
          _db.pullRequests,
          (t) => t.id.equals(id),
        );
      });
      _logger.info('PR #$id deleted');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Delete PR #$id failed: $err');
      return Either.left(Failure(message: 'Delete PR failed', cause: err));
    }
  }

  Future<Either<Failure, void>> deleteByProjectAlias(String alias) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    try {
      _logger.info('Deleting PRs by project alias: $alias');
      final prs = await (_db.select(_db.pullRequests)
        ..where((t) => t.projectAlias.equals(alias))).get();
      final prIds = prs.map((p) => p.id).toList();
      await _db.batch((batch) {
        for (final prId in prIds) {
          batch.deleteWhere(
            _db.prEnvFlags,
            (t) => t.prId.equals(prId),
          );
        }
        batch.deleteWhere(
          _db.pullRequests,
          (t) => t.projectAlias.equals(alias),
        );
      });
      _logger.info('PRs deleted for project alias: $alias');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Delete PRs by alias $alias failed: $err');
      return Either.left(
        Failure(message: 'Delete PRs by project alias failed', cause: err),
      );
    }
  }
}
