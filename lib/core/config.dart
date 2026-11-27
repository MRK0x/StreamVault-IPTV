/// Build configuration. Secrets and endpoints are passed at build time via
/// --dart-define; no real secrets or server addresses are stored in the repo.
///
/// Example iOS build:
///   flutter build ipa \
///     --dart-define=HMAC_SECRET=<hmac-secret> \
///     --dart-define=MANAGED_PROVIDER_URL=https://api.example.com \
///     --dart-define=VOICE_SERVICE_URL=https://voice.example.com \
///     --dart-define=APP_USER_AGENT="<user-agent>"
class AppConfig {
  AppConfig._();

  /// Base URL of the API gateway.
  static const String baseUrl = String.fromEnvironment(
    'MANAGED_PROVIDER_URL',
    defaultValue: 'https://api.example.com',
  );

  /// Base URL of the voice rooms / watch-party service.
  static const String voiceUrl = String.fromEnvironment(
    'VOICE_SERVICE_URL',
    defaultValue: 'https://voice.example.com',
  );

  /// HMAC secret, baked in at build time (empty in dev/demo mode).
  static const String hmacSecret = String.fromEnvironment('HMAC_SECRET');

  /// Custom User-Agent sent with every request, including video.
  /// Override at build time with --dart-define=APP_USER_AGENT=...
  static const String userAgent = String.fromEnvironment(
    'APP_USER_AGENT',
    defaultValue: 'StreamVault-IPTV/1.0',
  );

  /// Demo (mock) mode: runs the UI on sample data without a server.
  /// Becomes false automatically when a real HMAC_SECRET is passed.
  static bool get useMockData => hmacSecret.isEmpty;
}
