import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/l10n/app_localizations.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/pr_sync_service.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/features/pr_list/pr_form_dialog.dart';
import 'package:pr_list/features/pr_list/pr_list_notifier.dart';
import 'package:pr_list/features/pr_list/pr_list_page.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:pr_list/features/projects/projects_notifier.dart';
import 'package:pr_list/features/projects/projects_providers.dart';

class _MockPrRepository extends Mock implements PrRepository {}

class _MockProviderRegistry extends Mock implements ProviderRegistry {}

class _MockProjectRepository extends Mock implements ProjectRepository {}

class _MockGitClient extends Mock implements GitClient {}

class _MockPrSyncService extends Mock implements PrSyncService {}

class _MockAppDatabase extends Mock implements AppDatabase {}

void main() {
  late _MockPrRepository prRepository;
  late _MockProviderRegistry providerRegistry;
  late _MockProjectRepository projectRepository;
  late _MockGitClient gitClient;
  late _MockPrSyncService prSyncService;
  late _MockAppDatabase appDatabase;

  setUp(() {
    prRepository = _MockPrRepository();
    providerRegistry = _MockProviderRegistry();
    projectRepository = _MockProjectRepository();
    gitClient = _MockGitClient();
    prSyncService = _MockPrSyncService();
    appDatabase = _MockAppDatabase();

    when(() => prRepository.watchAll()).thenAnswer(
      (_) => Stream<List<PullRequest>>.value(<PullRequest>[_samplePr()]),
    );
    when(() => projectRepository.watchAll()).thenAnswer(
      (_) => Stream<List<Project>>.value(<Project>[_sampleProject()]),
    );
    when(() => prSyncService.nextRunStream).thenAnswer(
      (_) => Stream<DateTime?>.value(
        DateTime.now().add(const Duration(minutes: 10)),
      ),
    );
    when(() => prSyncService.isSyncRunning).thenReturn(false);
    when(() => prSyncService.triggerNowAndReset()).thenAnswer((_) async {});
    when(() => appDatabase.transaction<void>(any())).thenAnswer((invocation) {
      final Future<void> Function() callback =
          invocation.positionalArguments.first as Future<void> Function();
      return callback();
    });
  });

  testWidgets('disables ticket closed checkbox when Jira ticket is empty', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        overrides: _providerOverrides(
          prRepository,
          providerRegistry,
          projectRepository,
          gitClient,
          prSyncService,
          appDatabase,
        ),
        child: const PrFormDialog(),
      ),
    );

    await tester.pumpAndSettle();
    final CheckboxListTile tile = tester.widget<CheckboxListTile>(
      find.byType(CheckboxListTile),
    );
    expect(tile.onChanged, isNull);
  });

  testWidgets('shows inline validation errors for branch and PR URL', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        overrides: _providerOverrides(
          prRepository,
          providerRegistry,
          projectRepository,
          gitClient,
          prSyncService,
          appDatabase,
        ),
        child: const PrFormDialog(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).at(0), 'my-project');
    await tester.enterText(find.byType(TextFormField).at(1), 'feature broken');
    await tester.enterText(find.byType(TextFormField).at(3), 'abc');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('Branch cannot contain spaces'), findsOneWidget);
    expect(find.text('Invalid PR URL'), findsOneWidget);
  });

  testWidgets('toggles PR list between grouped list and kanban view', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        overrides: _providerOverrides(
          prRepository,
          providerRegistry,
          projectRepository,
          gitClient,
          prSyncService,
          appDatabase,
        ),
        child: const PrListPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Unreleased'), findsOneWidget);
    expect(find.byIcon(Icons.view_kanban), findsOneWidget);

    await tester.tap(find.byIcon(Icons.view_kanban));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.view_list), findsOneWidget);
  });

  testWidgets('shows scheduler action with countdown text in app bar', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        overrides: _providerOverrides(
          prRepository,
          providerRegistry,
          projectRepository,
          gitClient,
          prSyncService,
          appDatabase,
        ),
        child: const PrListPage(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.schedule), findsOneWidget);
    expect(find.textContaining('Next run in'), findsOneWidget);
  });
}

List<Override> _providerOverrides(
  _MockPrRepository prRepository,
  _MockProviderRegistry providerRegistry,
  _MockProjectRepository projectRepository,
  _MockGitClient gitClient,
  _MockPrSyncService prSyncService,
  _MockAppDatabase appDatabase,
) {
  final PrListNotifier prListNotifier = PrListNotifier(
    prRepository,
    providerRegistry,
    projectRepository,
    gitClient,
  );
  final ProjectsNotifier projectsNotifier = ProjectsNotifier(
    projectRepository,
    prRepository,
    appDatabase,
  );
  return <Override>[
    prListNotifierProvider.overrideWith((ref) => prListNotifier),
    projectsNotifierProvider.overrideWith((ref) => projectsNotifier),
    prSyncServiceProvider.overrideWithValue(prSyncService),
  ];
}

Widget _buildTestApp({
  required List<Override> overrides,
  required Widget child,
}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: const <Locale>[Locale('en'), Locale('it')],
      home: Scaffold(body: child),
    ),
  );
}

PullRequest _samplePr() {
  final DateTime now = DateTime(2026, 1, 1);
  return PullRequest(
    id: 1,
    projectAlias: 'my-project',
    branch: 'feature/test',
    jiraTicket: 'ABC-1',
    prLink: 'https://dev.azure.com/org/project/_git/repo/pullrequest/1',
    provider: 'azure_devops',
    providerPrId: '1',
    providerStatus: 'completed',
    lastCommitSha: 'abc123',
    isTicketClosed: false,
    isOnDevelop: false,
    isOnUat: false,
    isOnPreprod: false,
    createdAt: now,
    updatedAt: now,
  );
}

Project _sampleProject() {
  final DateTime now = DateTime(2026, 1, 1);
  return Project(
    id: 1,
    alias: 'my-project',
    path: '/tmp/repo',
    createdAt: now,
    updatedAt: now,
  );
}
