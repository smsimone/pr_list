import 'package:drift/drift.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class EnvironmentMappingRepository {
  final AppDatabase _db;

  EnvironmentMappingRepository(this._db);

  Future<Either<Failure, List<EnvironmentMapping>>> getAll() async {
    try {
      final query = _db.select(_db.environmentMappings)
        ..orderBy([(t) => OrderingTerm(expression: t.sortOrder)]);
      final items = await query.get();
      return Either.right(items);
    } catch (err) {
      return Either.left(Failure(
        message: 'Failed to load environment mappings',
        cause: err,
      ));
    }
  }

  Future<Either<Failure, void>> saveAll(
    List<Insertable<EnvironmentMapping>> items,
  ) async {
    try {
      await _db.batch((batch) {
        batch.deleteAll(_db.environmentMappings);
        for (final item in items) {
          batch.insert(_db.environmentMappings, item);
        }
      });
      return const Either.right(null);
    } catch (err) {
      return Either.left(Failure(
        message: 'Failed to save environment mappings',
        cause: err,
      ));
    }
  }
}
