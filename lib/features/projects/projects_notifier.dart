import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/features/projects/projects_state.dart';

class ProjectsNotifier extends StateNotifier<ProjectsState> {
  final ProjectRepository _repository;
  final PrRepository _prRepository;
  final AppDatabase _db;
  StreamSubscription<List<Project>>? _subscription;

  ProjectsNotifier(this._repository, this._prRepository, this._db)
    : super(ProjectsState.initial()) {
    _subscription = _repository.watchAll().listen(
      (items) {
        state = state.copyWith(items: items, isLoading: false);
      },
      onError: (_) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Failed to load projects',
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Either<Exception, void>> addProject({
    required String alias,
    required String path,
  }) async {
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    final result = await _repository.create(alias: alias, path: path);
    if (result.isLeft) {
      return Either.left(Exception(result.left.message));
    }
    return const Either.right(null);
  }

  Future<Either<Exception, void>> updateProject({
    required int id,
    required String alias,
    required String path,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(alias.trim().isNotEmpty, 'alias must not be empty');
    assert(path.trim().isNotEmpty, 'path must not be empty');
    final result = await _repository.update(id: id, alias: alias, path: path);
    if (result.isLeft) {
      return Either.left(Exception(result.left.message));
    }
    return const Either.right(null);
  }

  Future<Either<Exception, void>> deleteProject(int id) async {
    assert(id > 0, 'id must be greater than 0');
    try {
      await _db.transaction(() async {
        final projectResult = await _repository.getById(id);
        if (projectResult.isLeft) {
          throw Exception(projectResult.left.message);
        }
        final project = projectResult.right;
        if (project == null) {
          throw Exception('Project not found');
        }

        final deletePrsResult = await _prRepository.deleteByProjectAlias(
          project.alias,
        );
        if (deletePrsResult.isLeft) {
          throw Exception(deletePrsResult.left.message);
        }

        final deleteProjectResult = await _repository.delete(id);
        if (deleteProjectResult.isLeft) {
          throw Exception(deleteProjectResult.left.message);
        }
      });
    } catch (err) {
      return Either.left(Exception('Delete project failed: $err'));
    }
    return const Either.right(null);
  }
}
