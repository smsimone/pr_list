import 'package:pr_list/core/db/app_database.dart';

bool isValidUrl(String? text) {
  if (text == null || text.trim().isEmpty) return false;
  final uri = Uri.tryParse(text.trim());
  return uri != null && uri.hasScheme && uri.hasAuthority;
}

String extractTicketName(String? input) {
  if (input == null || input.trim().isEmpty) return '(no ticket)';
  final text = input.trim();
  final uri = Uri.tryParse(text);
  if (uri != null && uri.hasScheme && uri.hasAuthority) {
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isNotEmpty) return segments.last;
  }
  return text;
}

String ticketCardTitle(PullRequest pr) {
  String trailing = "";
  if (pr.jiraTicket != null) {
    trailing = " - ${extractTicketName(pr.jiraTicket!)}";
  }
  return '${pr.projectAlias} $trailing'; // - ${extractTicketName(pr.jiraTicket ?? pr.prLink)}';
}
