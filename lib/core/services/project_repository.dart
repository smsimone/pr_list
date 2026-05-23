import 'package:drift/drift.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class ProjectRepository {
  final _logger = Logger('ProjectRepository');
  final AppDatabase _db;

  ProjectRepository(this._db);

  Stream<List<Project>> watchAll() {
    return _db.select(_db.projects).watch();
  }

  Future<Either<Failure, List<Project>>> getAll() async {
    try {
      final items = await _db.select(_db.projects).get();
      _logger.info('Loaded ${items.length} project(s)');
      return Either.right(items);
    } catch (err) {
      _logger.warning('Load projects failed: $err');
      return Either.left(Failure(message: 'Load projects failed', cause: err));
    }
  }

  Future<Either<Failure, Project?>> getByAlias(String alias) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    try {
      final query = _db.select(_db.projects)
        ..where((tbl) => tbl.alias.equals(alias));
      final item = await query.getSingleOrNull();
      return Either.right(item);
    } catch (err) {
      _logger.warning('getByAlias($alias) failed: $err');
      return Either.left(Failure(message: 'Load project failed', cause: err));
    }
  }

  Future<Either<Failure, Project?>> getById(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      final query = _db.select(_db.projects)..where((tbl) => tbl.id.equals(id));
      final item = await query.getSingleOrNull();
      return Either.right(item);
    } catch (err) {
      _logger.warning('getById($id) failed: $err');
      return Either.left(Failure(message: 'Load project failed', cause: err));
    }
  }

  Future<Either<Failure, int>> create({
    required String alias,
    required String path,
    int? color,
  }) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    final now = DateTime.now();
    try {
      _logger.info('Creating project: $alias at $path (color=$color)');
      final id = await _db
          .into(_db.projects)
          .insert(
            ProjectsCompanion.insert(
              alias: alias,
              path: path,
              color: Value(color),
              createdAt: now,
              updatedAt: now,
            ),
          );
      _logger.info('Project #$id created: $alias');
      return Either.right(id);
    } catch (err) {
      _logger.severe('Create project $alias failed: $err');
      return Either.left(Failure(message: 'Create project failed', cause: err));
    }
  }

  Future<Either<Failure, void>> update({
    required int id,
    required String alias,
    required String path,
    int? color,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    try {
      _logger.info('Updating project #$id: $alias (color=$color)');
      await (_db.update(_db.projects)..where((t) => t.id.equals(id))).write(
        ProjectsCompanion(
          alias: Value(alias),
          path: Value(path),
          color: Value(color),
          updatedAt: Value(DateTime.now()),
        ),
      );
      _logger.info('Project #$id updated');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Update project #$id failed: $err');
      return Either.left(Failure(message: 'Update project failed', cause: err));
    }
  }

  Future<Either<Failure, void>> delete(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      _logger.info('Deleting project #$id');
      await (_db.delete(_db.projects)..where((t) => t.id.equals(id))).go();
      _logger.info('Project #$id deleted');
      return const Either.right(null);
    } catch (err) {
      _logger.severe('Delete project #$id failed: $err');
      return Either.left(Failure(message: 'Delete project failed', cause: err));
    }
  }
}
