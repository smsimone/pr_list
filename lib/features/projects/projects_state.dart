import 'package:pr_list/core/db/app_database.dart';

class ProjectsState {
  final List<Project> items;
  final bool isLoading;
  final String? errorMessage;

  const ProjectsState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  factory ProjectsState.initial() {
    return const ProjectsState(
      items: <Project>[],
      isLoading: true,
      errorMessage: null,
    );
  }

  ProjectsState copyWith({
    List<Project>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProjectsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
