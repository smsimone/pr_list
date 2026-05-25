import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:logging/logging.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class PullRequests extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get projectAlias => text()();
  TextColumn get jiraTicket => text().nullable()();
  TextColumn get prLink => text().nullable()();
  TextColumn get provider => text().nullable()();
  TextColumn get providerPrId => text().nullable()();
  TextColumn get providerStatus => text().nullable()();
  TextColumn get lastCommitSha => text().nullable()();
  TextColumn get lastMergeCommitSha => text().nullable()();
  BoolColumn get isTicketClosed =>
      boolean().withDefault(const Constant(false))();
  TextColumn get ticketStatus => text().nullable()();
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
  IntColumn get color => integer().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  List<Set<Column>> get uniqueKeys => [
    {alias},
  ];
}

class EnvironmentMappings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sortOrder => integer()();
  TextColumn get environmentName => text()();
  TextColumn get branchPattern => text()();
}

class PrEnvFlags extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prId => integer().references(PullRequests, #id)();
  IntColumn get envMappingId => integer().references(EnvironmentMappings, #id)();

  @override
  List<Set<Column>> get uniqueKeys => [
    {prId, envMappingId},
  ];
}

@DriftDatabase(tables: [
  PullRequests,
  SchemaMigrations,
  Projects,
  EnvironmentMappings,
  PrEnvFlags,
])
class AppDatabase extends _$AppDatabase {
  final _logger = Logger('AppDatabase');

  AppDatabase() : super(_openConnection()) {
    _logger.info('AppDatabase initialized, schemaVersion=$schemaVersion');
  }

  @override
  int get schemaVersion => _migrations.last.version;

  List<_MigrationStep> get _migrations => [
    _MigrationStep(
      version: 1,
      checksum: '20240522_init_clean',
      run: (Migrator m) async {
        await m.createTable(pullRequests);
        await m.createTable(schemaMigrations);
      },
    ),
    _MigrationStep(
      version: 2,
      checksum: '20240522_projects',
      run: (Migrator m) async => m.createTable(projects),
    ),
    _MigrationStep(
      version: 3,
      checksum: '20250523_project_color',
      run: (Migrator m) async {
        try {
          await m.addColumn(projects, projects.color);
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
            _logger.warning('Column "color" already exists, skipping migration v3');
          } else {
            rethrow;
          }
        }
      },
    ),
    _MigrationStep(
      version: 4,
      checksum: '20250523_environment_mappings',
      run: (Migrator m) async => m.createTable(environmentMappings),
    ),
    _MigrationStep(
      version: 5,
      checksum: '20250523_drop_branch_add_envflags',
      run: (Migrator m) async {
        await m.deleteTable('pull_requests');
        await m.createTable(pullRequests);
        await m.createTable(prEnvFlags);
      },
    ),
    _MigrationStep(
      version: 6,
      checksum: '20250525_ticket_status',
      run: (Migrator m) async {
        try {
          await m.addColumn(pullRequests, pullRequests.ticketStatus);
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
            _logger.warning('Column "ticketStatus" already exists, skipping migration v6');
          } else {
            rethrow;
          }
        }
      },
    ),
    _MigrationStep(
      version: 7,
      checksum: '20250525_merge_commit_sha',
      run: (Migrator m) async {
        try {
          await m.addColumn(pullRequests, pullRequests.lastMergeCommitSha);
        } catch (e) {
          if (e.toString().contains('duplicate column name')) {
            _logger.warning('Column "lastMergeCommitSha" already exists, skipping migration v7');
          } else {
            rethrow;
          }
        }
      },
    ),
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      _logger.info('Creating database from scratch');
      await m.createTable(schemaMigrations);
      await _applyMigrations(m, 0, schemaVersion);
    },
    onUpgrade: (Migrator m, int from, int to) async {
      _logger.info('Database migration: v$from -> v$to');
      await _applyMigrations(m, from, to);
    },
  );

  Future<void> _recordMigration(int version, String checksum) async {
    assert(version > 0, 'version must be greater than 0');
    assert(checksum.trim().isNotEmpty, 'checksum must not be empty');
    _logger.info('Recording migration v$version ($checksum)');
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
    final appliedVersions = await _loadAppliedVersions();
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
      final versions = await customSelect(
        'SELECT version FROM schema_migrations',
      ).map((row) => row.read<int>('version')).get();
      return versions;
    } catch (_) {
      return [];
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
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'pr_list.sqlite'));
    Logger('AppDatabase').info('Opening database at ${file.path}');
    return NativeDatabase(file);
  });
}
