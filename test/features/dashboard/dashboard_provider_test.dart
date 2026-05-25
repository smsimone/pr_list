import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';
import 'package:pr_list/features/dashboard/dashboard_provider.dart';
import 'package:pr_list/features/dashboard/dashboard_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MockPrRepository extends Mock implements PrRepository {}

PullRequest _pr({int id = 1, String jiraTicket = 'ABC-1'}) {
  final now = DateTime(2026, 1, 1);
  return PullRequest(
    id: id,
    projectAlias: 'my-project',
    jiraTicket: jiraTicket,
    prLink: 'https://dev.azure.com/org/project/_git/repo/pullrequest/$id',
    provider: 'azure_devops',
    providerPrId: '$id',
    providerStatus: 'completed',
    lastCommitSha: 'abc123',
    isTicketClosed: false,
    createdAt: now,
    updatedAt: now,
  );
}

void main() {
  late _MockPrRepository mockRepo;
  late StreamController<List<PullRequest>> streamController;

  setUp(() {
    mockRepo = _MockPrRepository();
    streamController = StreamController<List<PullRequest>>.broadcast();

    when(() => mockRepo.watchAll()).thenAnswer((_) => streamController.stream);
    when(() => mockRepo.getAllEnvFlags()).thenAnswer(
      (_) async => const Either.right(<int, List<int>>{}),
    );

    GetIt.instance.registerLazySingleton<PrRepository>(() => mockRepo);
  });

  tearDown(() async {
    await streamController.close();
    await GetIt.instance.unregister<PrRepository>();
  });

  /// Helper: creates a ProviderContainer, triggers dashboardProvider,
  /// and starts collecting emitted states.
  Future<({ProviderContainer container, List<DashboardState> emitted})>
      setupContainer() async {
    final container = ProviderContainer();
    final emitted = <DashboardState>[];
    // read triggers provider creation – must happen before stream emit
    container.read(dashboardProvider);
    container.listen<AsyncValue<DashboardState>>(
      dashboardProvider,
      (_, next) {
        next.whenData((state) => emitted.add(state));
      },
    );
    // give the provider time to subscribe to watchAll()
    await Future<void>.delayed(Duration.zero);
    return (container: container, emitted: emitted);
  }

  test('reloads env flags on each stream emission', () async {
    final setup = await setupContainer();
    final container = setup.container;
    final emitted = setup.emitted;
    addTearDown(container.dispose);

    // First emission: PR with no env flags
    streamController.add([_pr(id: 1)]);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, greaterThan(0));
    expect(emitted[0].notReleased.map((e) => e.id).toList(), [1]);
    expect(emitted[0].notClosed.map((e) => e.id).toList(), [1]);

    // Update mock: PR#1 now has env flag 7
    when(() => mockRepo.getAllEnvFlags()).thenAnswer(
      (_) async => const Either.right({1: [7]}),
    );

    // Same PR emitted again (simulates sync updating env flags)
    streamController.add([_pr(id: 1)]);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, 2);
    expect(emitted[1].notReleased.map((e) => e.id).toList(), []);
    expect(emitted[1].notClosed.map((e) => e.id).toList(), [1]);

    verify(() => mockRepo.getAllEnvFlags()).called(2);
  });

  test('handles PRs with and without env flags correctly', () async {
    final setup = await setupContainer();
    final container = setup.container;
    final emitted = setup.emitted;
    addTearDown(container.dispose);

    when(() => mockRepo.getAllEnvFlags()).thenAnswer(
      (_) async => const Either.right({1: [7]}),
    );

    streamController.add([_pr(id: 1), _pr(id: 2)]);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, greaterThan(0));
    expect(emitted[0].notReleased.map((e) => e.id).toList(), [2]);
  });

  test('handles getAllEnvFlags error gracefully', () async {
    final setup = await setupContainer();
    final container = setup.container;
    final emitted = setup.emitted;
    addTearDown(container.dispose);

    when(() => mockRepo.getAllEnvFlags()).thenAnswer(
      (_) async => Either.left(Failure(message: 'error')),
    );

    streamController.add([_pr(id: 1)]);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, greaterThan(0));
    expect(emitted[0].notReleased.map((e) => e.id).toList(), [1]);
  });

  test('filters PRs without jira ticket', () async {
    final setup = await setupContainer();
    final container = setup.container;
    final emitted = setup.emitted;
    addTearDown(container.dispose);

    streamController.add([_pr(id: 1, jiraTicket: '')]);
    await Future<void>.delayed(Duration.zero);

    expect(emitted.length, greaterThan(0));
    expect(emitted[0].notReleased, isEmpty);
    expect(emitted[0].notClosed, isEmpty);
  });
}
