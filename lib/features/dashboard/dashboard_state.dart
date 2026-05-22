import 'package:pr_list/core/db/app_database.dart';

class DashboardState {
  final List<PullRequest> notReleased;
  final List<PullRequest> notClosed;

  const DashboardState({
    required this.notReleased,
    required this.notClosed,
  });
}
