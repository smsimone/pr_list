import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class ProviderPullRequestInfo {
  final String provider;
  final String pullRequestId;
  final String status;
  final String lastCommitSha;
  final String? lastMergeCommitSha;

  const ProviderPullRequestInfo({
    required this.provider,
    required this.pullRequestId,
    required this.status,
    required this.lastCommitSha,
    this.lastMergeCommitSha,
  });
}

abstract class GitProvider {
  String get name;

  bool supportsUrl(String url);

  Either<Failure, String> extractPullRequestId(String url);

  Future<Either<Failure, ProviderPullRequestInfo>> fetchPullRequestInfo({
    required String url,
    required String pat,
    String? remoteUrl,
  });
}
