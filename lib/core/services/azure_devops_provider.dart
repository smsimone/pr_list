import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pr_list/core/services/git_provider.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class AzureDevOpsProvider implements GitProvider {
  final _logger = Logger('AzureDevOpsProvider');
  @override
  String get name => 'azure_devops';

  @override
  bool supportsUrl(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      _logger.warning('supportsUrl: invalid URL $url');
      return false;
    }
    final supported = parsed.host == 'dev.azure.com';
    _logger.info('supportsUrl($url) -> $supported');
    return supported;
  }

  @override
  Either<Failure, String> extractPullRequestId(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      _logger.warning('extractPullRequestId: invalid URL $url');
      return const Either.left(Failure(message: 'Invalid URL'));
    }
    if (parsed.host != 'dev.azure.com') {
      _logger.warning('extractPullRequestId: unsupported host ${parsed.host} from $url');
      return const Either.left(Failure(message: 'Unsupported host'));
    }
    if (parsed.pathSegments.isEmpty) {
      _logger.warning('extractPullRequestId: missing path segments in $url');
      return const Either.left(Failure(message: 'Missing path segments'));
    }
    final last = parsed.pathSegments.last;
    if (last.trim().isEmpty) {
      _logger.warning('extractPullRequestId: empty pull request id in $url');
      return const Either.left(Failure(message: 'Missing pull request id'));
    }
    _logger.info('extractPullRequestId($url) -> $last');
    return Either.right(last);
  }

  @override
  Future<Either<Failure, ProviderPullRequestInfo>> fetchPullRequestInfo({
    required String url,
    required String pat,
  }) async {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    assert(pat.trim().isNotEmpty, 'pat must not be empty');
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      return const Either.left(Failure(message: 'Invalid URL'));
    }
    if (parsed.host != 'dev.azure.com') {
      return const Either.left(Failure(message: 'Unsupported host'));
    }

    if (parsed.pathSegments.length < 4) {
      return const Either.left(
        Failure(message: 'Not enough path segments to build API URL'),
      );
    }

    final String organization = parsed.pathSegments[0];
    final String project = parsed.pathSegments[1];
    final String repository = parsed.pathSegments[2];
    final String pullRequestId = parsed.pathSegments.last;

    final apiUrl = Uri.parse(
      'https://dev.azure.com/$organization/$project/_apis/git/repositories/$repository/pullRequests/$pullRequestId?api-version=7.1-preview.1',
    );

    final auth = base64Encode(utf8.encode(':$pat'));
    _logger.info('GET $apiUrl');
    try {
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Basic $auth',
          'Accept': 'application/json',
        },
      );

      _logger.info('Azure response ${response.statusCode} for PR #$pullRequestId');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logger.warning('Azure error ${response.statusCode}: ${response.body}');
        return Either.left(
          Failure(
            message: 'Azure response ${response.statusCode}',
            cause: response.body,
          ),
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      final status = (body['status'] as String?) ?? 'unknown';
      final lastMergeSourceCommit =
          body['lastMergeSourceCommit'] as Map<String, dynamic>?;
      final lastCommit =
          (lastMergeSourceCommit?['commitId'] as String?) ?? '';

      _logger.info('Parsed PR #$pullRequestId: status=$status, commitId=$lastCommit');

      if (lastCommit.isEmpty) {
        _logger.warning('Missing last merge source commit for PR #$pullRequestId');
        return const Either.left(
          Failure(message: 'Missing last merge source commit'),
        );
      }

      return Either.right(
        ProviderPullRequestInfo(
          provider: name,
          pullRequestId: pullRequestId,
          status: status,
          lastCommitSha: lastCommit,
        ),
      );
    } catch (err) {
      _logger.severe('Azure request failed for PR #$pullRequestId: $err');
      return Either.left(Failure(message: 'Azure request failed', cause: err));
    }
  }
}
