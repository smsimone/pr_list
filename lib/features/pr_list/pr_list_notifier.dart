import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pr_list/core/db/app_database.dart';
import 'package:pr_list/core/services/git_client.dart';
import 'package:pr_list/core/services/pr_repository.dart';
import 'package:pr_list/core/services/provider_registry.dart';
import 'package:pr_list/core/services/project_repository.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/features/pr_list/pr_list_state.dart';

enum PrOperationErrorCode {
  projectNotFound,
  invalidProjectRepository,
  branchNotFound,
  persistenceFailure,
}

class PrOperationException implements Exception {
  final PrOperationErrorCode code;
  final String? details;

  const PrOperationException(this.code, {this.details});
}

class PrListNotifier extends StateNotifier<PrListState> {
  final PrRepository _repository;
  final ProviderRegistry _providerRegistry;
  final ProjectRepository _projectRepository;
  final GitClient _gitClient;
  StreamSubscription<List<PullRequest>>? _subscription;

  PrListNotifier(
    this._repository,
    this._providerRegistry,
    this._projectRepository,
    this._gitClient,
  ) : super(PrListState.initial()) {
    _subscription = _repository.watchAll().listen(
      (List<PullRequest> items) {
        state = state.copyWith(items: items, isLoading: false);
      },
      onError: (Object err) {
        state = state.copyWith(
          errorMessage: 'Failed to load PRs',
          isLoading: false,
        );
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  Future<Either<PrOperationException, void>> addPr({
    required String projectAlias,
    required String branch,
    String? jiraTicket,
    String? prLink,
  }) async {
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    String? provider;
    String? providerPrId;
    if (prLink != null && prLink.trim().isNotEmpty) {
      final matchedProvider = _providerRegistry.match(prLink);
      if (matchedProvider != null) {
        provider = matchedProvider.name;
        final result = matchedProvider.extractPullRequestId(prLink);
        if (result.isRight) {
          providerPrId = result.right;
        }
      }
    }
    final Either<PrOperationException, void> validation = await _validateBranch(
      projectAlias: projectAlias,
      branch: branch,
    );
    if (validation.isLeft) {
      return Either.left(validation.left);
    }

    final result = await _repository.create(
      projectAlias: projectAlias,
      branch: branch,
      jiraTicket: jiraTicket,
      prLink: prLink,
      provider: provider,
      providerPrId: providerPrId,
    );
    if (result.isLeft) {
      return Either.left(
        PrOperationException(
          PrOperationErrorCode.persistenceFailure,
          details: result.left.message,
        ),
      );
    }
    return const Either.right(null);
  }

  Future<Either<PrOperationException, void>> updatePr({
    required int id,
    required String projectAlias,
    required String branch,
    String? jiraTicket,
    String? prLink,
    required bool isTicketClosed,
  }) async {
    assert(id > 0, 'id must be greater than 0');
    assert(projectAlias.trim().isNotEmpty, 'projectAlias must not be empty');
    assert(branch.trim().isNotEmpty, 'branch must not be empty');
    String? provider;
    String? providerPrId;
    if (prLink != null && prLink.trim().isNotEmpty) {
      final matchedProvider = _providerRegistry.match(prLink);
      if (matchedProvider != null) {
        provider = matchedProvider.name;
        final result = matchedProvider.extractPullRequestId(prLink);
        if (result.isRight) {
          providerPrId = result.right;
        }
      }
    }
    final Either<PrOperationException, void> validation = await _validateBranch(
      projectAlias: projectAlias,
      branch: branch,
    );
    if (validation.isLeft) {
      return Either.left(validation.left);
    }

    final result = await _repository.updatePr(
      id: id,
      projectAlias: projectAlias,
      branch: branch,
      jiraTicket: jiraTicket,
      prLink: prLink,
      isTicketClosed: isTicketClosed,
      provider: provider,
      providerPrId: providerPrId,
    );
    if (result.isLeft) {
      return Either.left(
        PrOperationException(
          PrOperationErrorCode.persistenceFailure,
          details: result.left.message,
        ),
      );
    }
    return const Either.right(null);
  }

  Future<Either<Exception, void>> deletePr(int id) async {
    assert(id > 0, 'id must be greater than 0');
    final result = await _repository.delete(id);
    if (result.isLeft) {
      return Either.left(Exception(result.left.message));
    }
    return const Either.right(null);
  }

  Future<Either<PrOperationException, void>> _validateBranch({
    required String projectAlias,
    required String branch,
  }) async {
    final projectResult = await _projectRepository.getByAlias(projectAlias);
    if (projectResult.isLeft) {
      return Either.left(
        PrOperationException(
          PrOperationErrorCode.persistenceFailure,
          details: projectResult.left.message,
        ),
      );
    }
    final Project? project = projectResult.right;
    if (project == null) {
      return const Either.left(
        PrOperationException(PrOperationErrorCode.projectNotFound),
      );
    }

    final branchResult = await _gitClient.branchExists(
      branch,
      workingDirectory: project.path,
    );
    if (branchResult.isLeft) {
      return Either.left(
        PrOperationException(
          PrOperationErrorCode.invalidProjectRepository,
          details: branchResult.left.message,
        ),
      );
    }
    if (!branchResult.right) {
      return const Either.left(
        PrOperationException(PrOperationErrorCode.branchNotFound),
      );
    }
    return const Either.right(null);
  }
}
