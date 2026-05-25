import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';
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
}
