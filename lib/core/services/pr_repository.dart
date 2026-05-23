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
    required String branch,
    String? jiraTicket,
    String? prLink,
    String? provider,
    String? providerPrId,
  }) async {
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    final now = DateTime.now();
    try {
      _logger.info('Creating PR: $branch @ $projectAlias');
      final id = await _db
          .into(_db.pullRequests)
          .insert(
            PullRequestsCompanion.insert(
              projectAlias: projectAlias,
              branch: branch,
              jiraTicket: Value(jiraTicket),
              prLink: Value(prLink),
              provider: Value(provider),
              providerPrId: Value(providerPrId),
              createdAt: now,
              updatedAt: now,
            ),
          );
      _logger.info('PR #$id created: $branch @ $projectAlias');
      return Either.right(id);
    } catch (err) {
      _logger.severe('Create PR failed: $err');
      return Either.left(Failure(message: 'Create PR failed', cause: err));
    }
  }

  Future<Either<Failure, void>> updatePr({
    required int id,
    required String projectAlias,
    required String branch,
    String? jiraTicket,
    String? prLink,
    required bool isTicketClosed,
    String? provider,
    String? providerPrId,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    try {
      _logger.info('Updating PR #$id: $branch @ $projectAlias');
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          projectAlias: Value(projectAlias),
          branch: Value(branch),
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
      _logger.info('Updating provider info for PR #$id: status=$providerStatus, sha=$lastCommitSha');
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          provider: Value(provider),
          providerPrId: Value(providerPrId),
          providerStatus: Value(providerStatus),
          lastCommitSha: Value(lastCommitSha),
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

  Future<Either<Failure, void>> updateEnvironmentFlags({
    required int id,
    required bool isOnDevelop,
    required bool isOnUat,
    required bool isOnPreprod,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      _logger.info(
        'Updating environment flags for PR #$id: develop=$isOnDevelop, uat=$isOnUat, preprod=$isOnPreprod',
      );
      await (_db.update(_db.pullRequests)..where((t) => t.id.equals(id))).write(
        PullRequestsCompanion(
          isOnDevelop: Value(isOnDevelop),
          isOnUat: Value(isOnUat),
          isOnPreprod: Value(isOnPreprod),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Update environment flags for PR #$id failed: $err');
      return Either.left(
        Failure(message: 'Update environment flags failed', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> delete(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      _logger.info('Deleting PR #$id');
      await (_db.delete(_db.pullRequests)..where((t) => t.id.equals(id))).go();
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
      await (_db.delete(
        _db.pullRequests,
      )..where((tbl) => tbl.projectAlias.equals(alias))).go();
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
