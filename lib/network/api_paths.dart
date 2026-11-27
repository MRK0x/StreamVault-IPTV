/// API paths — the clean `/api/…` surface the iOS build calls directly.
class ApiPaths {
  ApiPaths._();

  // Account
  static const login = '/api/auth/login/';
  static const register = '/api/auth/register/';
  static const refresh = '/api/auth/refresh/';
  static const me = '/api/me/';
  static const plans = '/api/plans/';

  /// Redeem a subscription coupon — requires Bearer. Success is 201; 400 =
  /// code rejected.
  static const redeem = '/api/subscriptions/redeem/';
  static const appVersion = '/api/app/version/';
  static const fcmToken = '/api/devices/fcm-token/';

  /// The user's active devices (GET only — confirmed by an OPTIONS probe).
  static const devices = '/api/devices/';

  /// Sign out a device: **DELETE only** — frees a seat and revokes the
  /// device's tokens.
  static String device(int id) => '/api/devices/$id/';

  // Catalog (Xtream envelope)
  static const tvAccount = '/api/tv/account';
  static const liveCategories = '/api/tv/live/categories';
  static const liveStreams = '/api/tv/live/streams';
  static const vodCategories = '/api/tv/vod/categories';
  static const vodStreams = '/api/tv/vod/streams';
  static const seriesCategories = '/api/tv/series/categories';
  static const series = '/api/tv/series';

  /// Series details + episodes. In Xtream it's the episode (not the series)
  /// that has a stream.
  static String seriesInfo(Object seriesId) => '/api/tv/series/$seriesId';

  static const epg = '/api/tv/epg';

  // Stream resolve → 302 to the CDN
  static String liveStream(Object id) => '/api/tv/stream/live/$id.ts';
  static String movieStream(Object id) => '/api/tv/stream/movie/$id.mp4';
  static String seriesStream(Object id) => '/api/tv/stream/series/$id.mp4';
}
