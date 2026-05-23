import 'package:logging/logging.dart';
import 'package:pr_list/core/services/git_provider.dart';

class ProviderRegistry {
  final _logger = Logger('ProviderRegistry');
  final List<GitProvider> _providers;

  ProviderRegistry(this._providers) {
    final names = _providers.map((p) => p.name).join(', ');
    _logger.info('Registered providers: [$names]');
  }

  GitProvider? match(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    for (final GitProvider provider in _providers) {
      if (provider.supportsUrl(url)) {
        _logger.info('Matching $url -> ${provider.name}');
        return provider;
      }
    }
    _logger.warning('No provider supports URL: $url');
    return null;
  }
}
