import 'package:pr_list/core/db/app_database.dart';

class PrListState {
  final List<PullRequest> items;
  final bool isLoading;
  final String? errorMessage;

  const PrListState({
    required this.items,
    required this.isLoading,
    required this.errorMessage,
  });

  factory PrListState.initial() {
    return const PrListState(
      items: <PullRequest>[],
      isLoading: true,
      errorMessage: null,
    );
  }

  PrListState copyWith({
    List<PullRequest>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return PrListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}
