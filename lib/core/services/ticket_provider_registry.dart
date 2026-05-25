import 'package:logging/logging.dart';
import 'package:pr_list/core/services/ticket_provider.dart';

class TicketProviderRegistry {
  final _logger = Logger('TicketProviderRegistry');
  final List<TicketProvider> _providers;

  TicketProviderRegistry(this._providers) {
    final names = _providers.map((p) => p.name).join(', ');
    _logger.info('Registered ticket providers: [$names]');
  }

  TicketProvider? match(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    for (final TicketProvider provider in _providers) {
      if (provider.supportsUrl(url)) {
        _logger.info('Matching $url -> ${provider.name}');
        return provider;
      }
    }
    _logger.warning('No ticket provider supports URL: $url');
    return null;
  }
}
