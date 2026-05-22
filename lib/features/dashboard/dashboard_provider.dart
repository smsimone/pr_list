import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/features/dashboard/dashboard_state.dart';

final dashboardProvider = StreamProvider<DashboardState>((ref) {
  final PrRepository repository = getIt<PrRepository>();
  return repository.watchAll().map((List<PullRequest> items) {
    final List<PullRequest> notReleased = items
        .where(
          (pr) => !(pr.isOnDevelop && pr.isOnUat && pr.isOnPreprod),
        )
        .toList();
    final List<PullRequest> notClosed =
        items.where((pr) => !pr.isTicketClosed).toList();
    return DashboardState(notReleased: notReleased, notClosed: notClosed);
  });
});
