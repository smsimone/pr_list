import 'package:pr_list/core/utils/either.dart';
import 'package:pr_list/core/utils/failure.dart';

class TicketInfo {
  final String provider;
  final String ticketId;
  final String status;
  final bool isClosed;

  const TicketInfo({
    required this.provider,
    required this.ticketId,
    required this.status,
    required this.isClosed,
  });
}

abstract class TicketProvider {
  String get name;

  bool supportsUrl(String url);

  Either<Failure, String> extractTicketId(String url);

  Future<Either<Failure, TicketInfo>> fetchTicketInfo({
    required String url,
    required String pat,
    String? instanceUrl,
    String? email,
  });
}
