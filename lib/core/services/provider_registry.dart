import 'package:pr_list/core/services/git_provider.dart';

class ProviderRegistry {
  final List<GitProvider> _providers;

  ProviderRegistry(this._providers);

  GitProvider? match(String url) {
    assert(url.trim().isNotEmpty, 'url must not be empty');
    for (final GitProvider provider in _providers) {
      if (provider.supportsUrl(url)) {
        return provider;
      }
    }
    return null;
  }
}
