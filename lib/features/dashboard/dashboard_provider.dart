import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/features/dashboard/dashboard_state.dart';

final dashboardProvider = StreamProvider<DashboardState>((ref) {
  final repository = getIt<PrRepository>();
  return repository.watchAll().map((items) {
    final withJira = items
        .where((pr) => pr.jiraTicket != null && pr.jiraTicket!.isNotEmpty)
        .toList();
    final notReleased = withJira
        .where((pr) => !(pr.isOnDevelop && pr.isOnUat && pr.isOnPreprod))
        .toList();
    final notClosed = withJira
        .where((pr) => !pr.isTicketClosed)
        .toList();
    return DashboardState(notReleased: notReleased, notClosed: notClosed);
  });
});
