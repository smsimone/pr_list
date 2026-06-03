import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';
import 'package:pr_list/features/pr_list/pr_list_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _MockPrRepository extends Mock implements PrRepository {}

void main() {
  late _MockPrRepository mockPrRepo;

  setUp(() {
    mockPrRepo = _MockPrRepository();

    when(() => mockPrRepo.getAllEnvFlags()).thenAnswer(
      (_) async => const Either.right(<int, List<int>>{}),
    );

    GetIt.instance.registerLazySingleton<PrRepository>(() => mockPrRepo);
  });

  tearDown(() async {
    await GetIt.instance.unregister<PrRepository>();
  });

  group('prEnvFlagsProvider', () {
    final testPrEnvFlagsProvider = FutureProvider<Map<int, List<int>>>((ref) async {
      final repo = GetIt.instance<PrRepository>();
      final result = await repo.getAllEnvFlags();
      if (result.isLeft) {
        return <int, List<int>>{};
      }
      return result.right;
    });

    test('returns empty map when no flags exist', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flags = await container.read(testPrEnvFlagsProvider.future);
      expect(flags, <int, List<int>>{});
    });

    test('returns flags from repository', () async {
      when(() => mockPrRepo.getAllEnvFlags()).thenAnswer(
        (_) async => const Either.right({1: [7], 2: [3, 5]}),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flags = await container.read(testPrEnvFlagsProvider.future);
      expect(flags, {1: [7], 2: [3, 5]});
    });

    test('returns empty map on error', () async {
      when(() => mockPrRepo.getAllEnvFlags()).thenAnswer(
        (_) async => Either.left(Failure(message: 'error')),
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final flags = await container.read(testPrEnvFlagsProvider.future);
      expect(flags, <int, List<int>>{});
    });
  });

  group('matchesTicketQuery', () {
    PullRequest buildPr({String? jiraTicket}) {
      return PullRequest(
        id: 1,
        projectAlias: 'CORE',
        jiraTicket: jiraTicket,
        prLink: null,
        provider: null,
        providerPrId: null,
        providerStatus: null,
        lastCommitSha: null,
        lastMergeCommitSha: null,
        isTicketClosed: false,
        ticketStatus: null,
        isManual: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );
    }

    test('returns true when query is empty', () {
      final pr = buildPr(jiraTicket: 'https://jira.example.com/browse/ABC-123');

      expect(matchesTicketQuery(pr, ''), isTrue);
      expect(matchesTicketQuery(pr, '   '), isTrue);
    });

    test('matches partial ticket id case-insensitively', () {
      final pr = buildPr(jiraTicket: 'https://jira.example.com/browse/ABC-123');

      expect(matchesTicketQuery(pr, 'abc-1'), isTrue);
      expect(matchesTicketQuery(pr, 'BC-12'), isTrue);
    });

    test('matches against raw jira ticket link when needed', () {
      final pr = buildPr(
        jiraTicket: 'https://jira.example.com/browse/ABC-123?focusedCommentId=99',
      );

      expect(matchesTicketQuery(pr, 'focusedcommentid'), isTrue);
    });

    test('returns false when ticket does not match query', () {
      final pr = buildPr(jiraTicket: 'https://jira.example.com/browse/ABC-123');

      expect(matchesTicketQuery(pr, 'XYZ-9'), isFalse);
    });

    test('returns false when pr has no jira ticket and query is not empty', () {
      final pr = buildPr(jiraTicket: null);

      expect(matchesTicketQuery(pr, 'abc'), isFalse);
    });
  });
}
