import 'package:drift/drift.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class ProjectRepository {
  final AppDatabase _db;

  ProjectRepository(this._db);

  Stream<List<Project>> watchAll() {
    return _db.select(_db.projects).watch();
  }

  Future<Either<Failure, List<Project>>> getAll() async {
    try {
      final items = await _db.select(_db.projects).get();
      return Either.right(items);
    } catch (err) {
      return Either.left(Failure(message: 'Load projects failed', cause: err));
    }
  }

  Future<Either<Failure, Project?>> getByAlias(String alias) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    try {
      final query = _db.select(_db.projects)
        ..where((tbl) => tbl.alias.equals(alias));
      final Project? item = await query.getSingleOrNull();
      return Either.right(item);
    } catch (err) {
      return Either.left(Failure(message: 'Load project failed', cause: err));
    }
  }

  Future<Either<Failure, int>> create({
    required String alias,
    required String path,
  }) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    final DateTime now = DateTime.now();
    try {
      final int id = await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              alias: alias,
              path: path,
              createdAt: now,
              updatedAt: now,
            ),
          );
      return Either.right(id);
    } catch (err) {
      return Either.left(Failure(message: 'Create project failed', cause: err));
    }
  }

  Future<Either<Failure, void>> update({
    required int id,
    required String alias,
    required String path,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    try {
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          alias: Value(alias),
          path: Value(path),
          updatedAt: Value(DateTime.now()),
        ),
      );
      return const Either.right(null);
    } catch (err) {
      return Either.left(Failure(message: 'Update project failed', cause: err));
    }
  }

  Future<Either<Failure, void>> delete(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
      return const Either.right(null);
    } catch (err) {
      return Either.left(Failure(message: 'Delete project failed', cause: err));
    }
  }
}
