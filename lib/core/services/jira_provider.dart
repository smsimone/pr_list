import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:pr_list/core/services/ticket_provider.dart';
import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class JiraProvider implements TicketProvider {
  final _logger = Logger('JiraProvider');
  @override
  String get name => 'jira';

  @override
  bool supportsUrl(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      _logger.warning('supportsUrl: invalid URL $url');
      return false;
    }
    final supported = parsed.host.contains('atlassian.net') ||
        parsed.host.contains('jira');
    _logger.info('supportsUrl($url) -> $supported');
    return supported;
  }

  @override
  Either<Failure, String> extractTicketId(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) {
      _logger.warning('extractTicketId: invalid URL $url');
      return const Either.left(Failure(message: 'Invalid URL'));
    }
    if (parsed.pathSegments.isEmpty) {
      _logger.warning('extractTicketId: missing path segments in $url');
      return const Either.left(Failure(message: 'Missing path segments'));
    }
    final last = parsed.pathSegments.last;
    if (last.trim().isEmpty) {
      _logger.warning('extractTicketId: empty ticket id in $url');
      return const Either.left(Failure(message: 'Missing ticket id'));
    }
    _logger.info('extractTicketId($url) -> $last');
    return Either.right(last);
  }

  @override
  Future<Either<Failure, TicketInfo>> fetchTicketInfo({
    required String url,
    required String pat,
    String? instanceUrl,
    String? email,
  }) async {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    assert(pat.trim().isNotEmpty, 'pat must not be empty');

    final String ticketId = _extractId(url);
    if (ticketId.isEmpty) {
      return const Either.left(
        Failure(message: 'Could not extract ticket ID from URL'),
      );
    }

    final baseUrl = (instanceUrl != null && instanceUrl.trim().isNotEmpty)
        ? instanceUrl.trim()
        : _extractBaseUrl(url);
    if (baseUrl == null) {
      return const Either.left(
        Failure(message: 'Could not determine Jira instance URL'),
      );
    }

    final apiUrl = Uri.parse('$baseUrl/rest/api/3/issue/$ticketId');
    final user = (email != null && email.trim().isNotEmpty) ? email.trim() : '';
    final auth = base64Encode(utf8.encode('$user:$pat'));
    _logger.info('GET $apiUrl');
    try {
      final response = await http.get(
        apiUrl,
        headers: {
          'Authorization': 'Basic $auth',
          'Accept': 'application/json',
        },
      );

      _logger.info('Jira response ${response.statusCode} for issue $ticketId');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        _logger.warning('Jira error ${response.statusCode}: ${response.body}');
        return Either.left(
          Failure(
            message: 'Jira response ${response.statusCode}',
            cause: response.body,
          ),
        );
      }

      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final fields = body['fields'] as Map<String, dynamic>?;
      final statusObj = fields?['status'] as Map<String, dynamic>?;
      final statusName = (statusObj?['name'] as String?) ?? 'unknown';
      final statusCategory = statusObj?['statusCategory'] as Map<String, dynamic>?;
      final categoryKey = (statusCategory?['key'] as String?) ?? '';
      final isClosed = categoryKey == 'done';

      _logger.info(
        'Parsed issue $ticketId: status=$statusName, isClosed=$isClosed',
      );

      return Either.right(
        TicketInfo(
          provider: name,
          ticketId: ticketId,
          status: statusName,
          isClosed: isClosed,
        ),
      );
    } catch (err) {
      _logger.severe('Jira request failed for issue $ticketId: $err');
      return Either.left(
        Failure(message: 'Jira request failed', cause: err),
      );
    }
  }

  String _extractId(String url) {
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null || parsed.pathSegments.isEmpty) return '';
    return parsed.pathSegments.last;
  }

  String? _extractBaseUrl(String url) {
    final Uri? parsed = Uri.tryParse(url);
    if (parsed == null) return null;
    return '${parsed.scheme}://${parsed.host}';
  }
}
