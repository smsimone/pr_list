import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/di/injection_container.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/features/projects/projects_notifier.dart';
import 'package:pr_list/features/projects/projects_state.dart';

final projectsNotifierProvider =
    StateNotifierProvider<ProjectsNotifier, ProjectsState>(
      (ref) => ProjectsNotifier(getIt<ProjectRepository>()),
    );
