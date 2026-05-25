import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/features/dashboard/dashboard_state.dart';

final dashboardProvider = StreamProvider<DashboardState>((ref) async* {
  final log = Logger('Dashboard');
  final repository = getIt<PrRepository>();

  await for (final items in repository.watchAll()) {
    final flagsResult = await repository.getAllEnvFlags();
    final flags = flagsResult.isLeft ? <int, List<int>>{} : flagsResult.right;

    final withJira = items
        .where((pr) => pr.jiraTicket != null && pr.jiraTicket!.isNotEmpty)
        .toList();
    final notReleased = withJira
        .where((pr) {
          final prFlags = flags[pr.id] ?? [];
          return prFlags.isEmpty;
        })
        .toList();
    final notClosed = withJira
        .where((pr) => !pr.isTicketClosed)
        .toList();
    log.info(
      'Dashboard: ${items.length} PRs, ${notReleased.length} not released, '
      '${notClosed.length} not closed',
    );
    yield DashboardState(notReleased: notReleased, notClosed: notClosed);
  }
});
