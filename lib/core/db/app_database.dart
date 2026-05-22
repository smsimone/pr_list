import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class PullRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectAlias => text()();
  TextColumn get branch => text()();
  TextColumn get jiraTicket => text().nullable()();
  TextColumn get prLink => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get providerPrId => text().nullable()();
  TextColumn get providerStatus => text().nullable()();
  TextColumn get lastCommitSha => text().nullable()();
  BoolColumn get isTicketClosed =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isOnDevelop => boolean().withDefault(const Constant(false))();
  BoolColumn get isOnUat => boolean().withDefault(const Constant(false))();
  BoolColumn get isOnPreprod => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class SchemaMigrations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get version => integer()();
  TextColumn get checksum => text()();
  DateTimeColumn get appliedAt => dateTime()();
}

class Projects extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get alias => text()();
  TextColumn get path => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => <Set<Column>>[
    <Column>{alias},
  ];
}

@DriftDatabase(tables: [PullRequests, SchemaMigrations, Projects])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => _migrations.last.version;

  List<_MigrationStep> get _migrations => <_MigrationStep>[
    _MigrationStep(
      version: 1,
      checksum: '20240522_init',
      run: (Migrator m) async => m.createTable(pullRequests),
    ),
    _MigrationStep(
      version: 2,
      checksum: '20240522_projects',
      run: (Migrator m) async => m.createTable(projects),
    ),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createTable(schemaMigrations);
      await _applyMigrations(m, 0, schemaVersion);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      await _applyMigrations(m, from, to);
    },
  );

  Future<void> _recordMigration(int version, String checksum) async {
    assert(version > 0, 'version must be greater than 0');
    assert(checksum.trim().isNotEmpty, 'checksum must not be empty');
    await into(schemaMigrations).insert(
      SchemaMigrationsCompanion.insert(
        version: version,
        checksum: checksum,
        appliedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _applyMigrations(Migrator m, int from, int to) async {
    assert(from >= 0, 'from must be greater or equal to 0');
    assert(to >= from, 'to must be greater or equal to from');
    final List<int> appliedVersions = await _loadAppliedVersions();
    for (final _MigrationStep step in _migrations) {
      if (step.version <= from || step.version > to) {
        continue;
      }
      if (appliedVersions.contains(step.version)) {
        continue;
      }
      await step.run(m);
      await _recordMigration(step.version, step.checksum);
    }
  }

  Future<List<int>> _loadAppliedVersions() async {
    try {
      final List<int> versions = await customSelect(
        'SELECT version FROM schema_migrations',
      ).map((row) => row.read<int>('version')).get();
      return versions;
    } catch (_) {
      return <int>[];
    }
  }
}

class _MigrationStep {
  final int version;
  final String checksum;
  final Future<void> Function(Migrator) run;

  const _MigrationStep({
    required this.version,
    required this.checksum,
    required this.run,
  });
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final Directory dir = await getApplicationDocumentsDirectory();
    final File file = File(p.join(dir.path, 'pr_list.sqlite'));
    return NativeDatabase(file);
  });
}
