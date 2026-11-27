import 'dart:async';
import 'dart:io' show Socket;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/config.dart';
import '../data/models/media_item.dart';
import '../network/api_paths.dart';
import '../network/hmac.dart';
import '../network/hosts.dart';

/// What is actually handed to the player after resolving the gateway redirect.
class PlaybackTarget {
  const PlaybackTarget({
    required this.url,
    required this.headers,
    this.isGateway = false,
  });

  final String url;
  final Map<String, String> headers;

  /// The target is our own gateway (it answered 200 with no redirect) — not
  /// probed: it just responded.
  final bool isGateway;
}

/// Resolving the link at the gateway failed — we don't open the player at all.
class PlaybackResolveException implements Exception {
  const PlaybackResolveException(this.statusCode);

  final int statusCode;

  /// 401/403 ⇒ the session expired or the signature was rejected (unrelated
  /// to the channel).
  bool get isAuth => statusCode == 401 || statusCode == 403;

  @override
  String toString() => 'PlaybackResolveException($statusCode)';
}

/// Builds the stream URL and the headers passed to the player
/// (media_kit/libmpv).
///
/// **We resolve the gateway redirect manually and don't let libmpv follow
/// it** — see [resolve].
class Playback {
  Playback._();

  static const _signer = HmacSigner(AppConfig.hmacSecret);

  /// Redacts the URL's secret before logging it — the CDN URL carries
  /// `?token=` (counterpart of `PlaybackLogSanitizer` on Android).
  static String sanitizeForLog(String url) => url.replaceAllMapped(
        RegExp(r'(token=)[^&]+'),
        (m) => '${m[1]}<redacted>',
      );

  /// Resolves the gateway redirect (302) ourselves and returns what is actually
  /// opened.
  ///
  /// ⚠️ **Why not let libmpv follow the 302?**
  /// The gateway redirects to a CDN over **plain http**, and mpv follows the
  /// redirect carrying the *same* headers to the new destination — so `Bearer`
  /// and `X-Ts`/`X-Sig` reach the CDN: it doesn't expect them so opening fails,
  /// **and the JWT leaks over unencrypted http**.
  /// Android handles this with `StripAuthOnPlainHttpInterceptor` (drops
  /// Authorization from any http request); we handle it here by splitting the
  /// two requests.
  ///
  /// The CDN authenticates via `?token=` in the URL itself, so **User-Agent
  /// alone** is enough — our request then matches any ordinary player (VLC),
  /// which is what the gateway expects.
  /// Number of attempts to catch a live CDN address before giving up.
  static const _maxCdnTries = 4;

  /// CDN hosts known to be dead — skipped immediately instead of waiting for a
  /// TCP timeout each time. Short TTL: the server may come back, so we don't
  /// ban it forever.
  static final Map<String, DateTime> _deadHosts = {};
  static const _deadTtl = Duration(minutes: 5);

  /// Replaced in tests (a real TCP probe doesn't work there).
  @visibleForTesting
  static Future<bool> Function(Uri uri)? probeOverride;

  @visibleForTesting
  static void resetDeadHosts() => _deadHosts.clear();

  /// Records a node whose **playback failed** so the next resolve avoids it.
  ///
  /// Complements the proactive probe: some nodes **accept a TCP connection but
  /// never stream**, so the probe can't catch them — only the player can, when
  /// it fails. The player calls this on failure.
  static void markDead(String host) {
    if (host.isEmpty) return;
    _deadHosts[host] = DateTime.now();
    debugPrint('PLAYER: node $host marked as dead, avoiding it');
  }

  /// Resolves the redirect and returns **a CDN address verified to accept
  /// connections**.
  ///
  /// ⚠️ **Why probe?** The gateway hands each request a different CDN address
  /// from the provider's pool, and **many of them are dead** (measured: 6 of 10
  /// accept neither TCP nor ping). Handing a dead address to mpv makes it hang
  /// for a long time on an unresponsive connection — the cause of "the channel
  /// loads forever", and why one channel works while another fails at random.
  ///
  /// Since **the same channel gets a different address on every request**,
  /// retrying usually catches a live one. The probe is raw TCP: fast, and it
  /// detects exactly what fails.
  static Future<PlaybackTarget> resolve(
    Dio dio,
    Uri gatewayUri, {
    String? accessToken,
  }) async {
    PlaybackTarget? last;
    for (var i = 1; i <= _maxCdnTries; i++) {
      final t =
          await _resolveWithRetry(dio, gatewayUri, accessToken: accessToken);
      last = t;
      if (t.isGateway) return t; // our gateway — it just responded

      final uri = Uri.parse(t.url);
      if (_knownDead(uri.host)) {
        debugPrint('PLAYER: ${uri.host} is known dead, requesting another now');
        continue; // no timeout wait
      }
      if (await _probe(uri)) {
        if (i > 1) debugPrint('PLAYER: got a live CDN after $i tries');
        return t;
      }
      _deadHosts[uri.host] = DateTime.now();
      debugPrint('PLAYER: dead CDN ${uri.host} (try $i/$_maxCdnTries)');
    }
    // Out of attempts: hand the last one to the player — the start guard
    // shows the failure to the user.
    debugPrint('PLAYER: every CDN address tried is dead');
    return last!;
  }

  static bool _knownDead(String host) {
    final at = _deadHosts[host];
    if (at == null) return false;
    if (DateTime.now().difference(at) > _deadTtl) {
      _deadHosts.remove(host); // TTL expired — give it another chance
      return false;
    }
    return true;
  }

  /// Quick TCP probe: does this address accept a connection at all?
  static Future<bool> _probe(Uri uri) async {
    final override = probeOverride;
    if (override != null) return override(uri);
    final port = uri.hasPort ? uri.port : (uri.scheme == 'https' ? 443 : 80);
    try {
      final s = await Socket.connect(uri.host, port,
          timeout: const Duration(seconds: 4));
      s.destroy();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// A single resolve with an **immediate retry** if it hits a broken
  /// connection.
  ///
  /// The first request may land on a broken pooled connection and hang until
  /// the timeout, while the next one opens a fresh connection and succeeds
  /// (observed pattern: failure followed by immediate success).
  static Future<PlaybackTarget> _resolveWithRetry(
    Dio dio,
    Uri gatewayUri, {
    String? accessToken,
  }) async {
    try {
      return await _resolveOnce(dio, gatewayUri,
          accessToken: accessToken, timeout: const Duration(seconds: 6));
    } on PlaybackResolveException {
      rethrow; // explicit gateway response (401/403/…) — retrying won't help
    } catch (e) {
      debugPrint('PLAYER resolve: first attempt failed ($e), retrying now');
      // Broken connection/timeout → retry immediately with a new connection
      // and a longer timeout.
      return _resolveOnce(dio, gatewayUri,
          accessToken: accessToken, timeout: const Duration(seconds: 12));
    }
  }

  static Future<PlaybackTarget> _resolveOnce(
    Dio dio,
    Uri gatewayUri, {
    String? accessToken,
    required Duration timeout,
  }) async {
    // dio adds User-Agent + Bearer + X-Ts/X-Sig automatically for our hosts.
    final Response<dynamic> r;
    try {
      r = await dio.getUri<dynamic>(
        gatewayUri,
        options: Options(
          followRedirects: false, // we want the 302 itself, not its target
          // 3xx is intended, so not an error. 4xx/5xx are deliberately left to
          // **throw**: that way AuthInterceptor.onError refreshes the expired
          // token (the gateway answers 403 here) and retries the request. If we
          // swallowed them with validateStatus:(_)=>true, refresh would break
          // entirely and the session would stay dead.
          validateStatus: (s) => s != null && s < 400,
          // ⚠️ **No ResponseType.stream here.**
          // A 302 has no body, so requesting it as a stream keeps the
          // connection **reserved** until the body is consumed — and cancelling
          // the subscription doesn't actually release it (measured: connections
          // pile up). The host's slots run out, the next request waits in the
          // queue until it times out, and the channel looks like it "loads
          // forever". In the default mode dio reads the empty body and releases
          // the connection immediately.
          receiveTimeout: timeout,
        ),
      );
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) rethrow; // network/timeout — not a gateway response
      throw PlaybackResolveException(res.statusCode ?? 0);
    }

    final code = r.statusCode ?? 0;
    debugPrint('PLAYER resolve: HTTP $code '
        'sent=${r.requestOptions.headers.keys.toList()}');

    if (code >= 300 && code < 400) {
      final loc = r.headers.value('location')?.trim();
      if (loc != null && loc.isNotEmpty) {
        // resolve also handles relative URLs.
        return PlaybackTarget(
          url: gatewayUri.resolve(loc).toString(),
          headers: {'User-Agent': AppConfig.userAgent}, // ❌ no Bearer, no signature
        );
      }
    }

    // Rare: the gateway streams directly with no redirect — open its URL with
    // the full headers.
    if (code == 200) {
      return PlaybackTarget(
        url: gatewayUri.toString(),
        headers: headers(gatewayUri, accessToken: accessToken),
        isGateway: true, // our host just responded — not probed
      );
    }

    throw PlaybackResolveException(code); // 401/403/other
  }

  /// The gateway URL that resolves (302) to the CDN.
  static Uri streamUri(MediaItem item) {
    final path = switch (item.kind) {
      MediaKind.live => ApiPaths.liveStream(item.id),
      MediaKind.movie => ApiPaths.movieStream(item.id),
      MediaKind.series => ApiPaths.seriesStream(item.id),
    };
    return Uri.parse('${AppConfig.baseUrl}$path');
  }

  /// **Gateway** headers — User-Agent + Bearer JWT + a fresh HMAC signature.
  ///
  /// ⚠️ Never pass these to the CDN (see [resolve]) — the Bearer is for our
  /// gateway (HTTPS) only. `isOurHost` guards them: no signature or token for
  /// a foreign host.
  static Map<String, String> headers(
    Uri uri, {
    String? accessToken,
    DateTime Function() clock = DateTime.now,
  }) {
    // Matches the Android source exactly: User-Agent + Bearer + HMAC signature
    // — nothing else.
    // (We don't send Icy-MetaData: with mp4 it makes the server reply with a
    //  Shoutcast frame and inject metadata bytes into the stream, so decoding
    //  fails.)
    final h = <String, String>{'User-Agent': AppConfig.userAgent};
    final ours = isOurHost(uri.host);
    if (ours && (accessToken?.isNotEmpty ?? false)) {
      h['Authorization'] = 'Bearer $accessToken';
    }
    if (ours && AppConfig.hmacSecret.isNotEmpty) {
      final ts = (clock().millisecondsSinceEpoch ~/ 1000).toString();
      final pq = uri.path + (uri.hasQuery ? '?${uri.query}' : '');
      h['X-Ts'] = ts;
      h['X-Sig'] = _signer.sign(
        method: 'GET',
        pathQuery: pq,
        tsSec: ts,
        body: const <int>[],
      );
    }
    return h;
  }
}
