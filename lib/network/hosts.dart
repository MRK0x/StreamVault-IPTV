import '../core/config.dart';

/// Root domains we own, derived from the configured endpoints
/// (e.g. `api.example.com` -> `example.com`).
final Set<String> _ourDomains = {
  for (final url in [AppConfig.baseUrl, AppConfig.voiceUrl]) _rootDomain(url),
}..remove('');

String _rootDomain(String url) {
  final host = Uri.tryParse(url)?.host ?? '';
  final parts = host.split('.');
  return parts.length <= 2 ? host : parts.sublist(parts.length - 2).join('.');
}

/// Whether [host] belongs to our domains. HMAC + User-Agent are applied only
/// to these hosts. Shared by the dio interceptors and the video player.
bool isOurHost(String host) =>
    _ourDomains.any((domain) => host == domain || host.endsWith('.$domain'));
