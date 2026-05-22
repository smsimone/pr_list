import 'package:drift/drift.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class PrRepository {
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
      final PullRequest? pr = await query.getSingleOrNull();
      return Either.right(pr);
    } catch (err) {
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
    final DateTime now = DateTime.now();
    try {
      final int id = await _db
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
      return Either.right(id);
    } catch (err) {
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
      return const Either.right(null);
    } catch (err) {
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
      return Either.left(
        Failure(message: 'Update environment flags failed', cause: err),
      );
    }
  }

  Future<Either<Failure, void>> delete(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      await (_db.delete(_db.pullRequests)..where((t) => t.id.equals(id))).go();
      return const Either.right(null);
    } catch (err) {
      return Either.left(Failure(message: 'Delete PR failed', cause: err));
    }
  }

  Future<Either<Failure, void>> deleteByProjectAlias(String alias) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    try {
      await (_db.delete(
        _db.pullRequests,
      )..where((tbl) => tbl.projectAlias.equals(alias))).go();
      return const Either.right(null);
    } catch (err) {
      return Either.left(
        Failure(message: 'Delete PRs by project alias failed', cause: err),
      );
    }
  }
}
