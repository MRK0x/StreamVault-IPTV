import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/player/playback.dart';

/// Fake adapter that returns whatever we specify, with no network.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options) respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

Dio _dioReturning(int code, {String? location, String body = ''}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter((_) => ResponseBody.fromBytes(
        utf8.encode(body),
        code,
        headers: {
          if (location != null) 'location': [location],
        },
      ));
  return dio;
}

void main() {
  final gateway =
      Uri.parse('https://api.example.com/api/tv/stream/live/95293.ts');

  group('resolve — gateway redirect is resolved manually', () {
    setUp(() => Playback.probeOverride = (_) async => true);
    tearDown(() {
      Playback.probeOverride = null;
      Playback.resetDeadHosts();
    });

    test('🔒 302 → CDN: sends User-Agent only, no token or signature', () async {
      final t = await _dioReturning(302,
              location: 'http://cdn.example.net/live/95293.ts?token=abc123')
          .let((d) => Playback.resolve(d, gateway, accessToken: 'JWT-SECRET'));

      expect(t.url, 'http://cdn.example.net/live/95293.ts?token=abc123');
      // Security rule: a JWT must never go out over http.
      expect(t.headers.containsKey('Authorization'), isFalse,
          reason: 'Bearer leaked to the CDN over http');
      expect(t.headers.containsKey('X-Sig'), isFalse);
      expect(t.headers.containsKey('X-Ts'), isFalse);
      expect(t.headers.keys.toList(), ['User-Agent']);
    });

    test('accepts any 3xx, not just 302', () async {
      for (final code in [301, 302, 303, 307, 308]) {
        final t = await _dioReturning(code, location: 'http://cdn.net/x.ts')
            .let((d) => Playback.resolve(d, gateway));
        expect(t.url, 'http://cdn.net/x.ts', reason: 'code=$code');
      }
    });

    test('relative location is resolved against the gateway URL', () async {
      final t = await _dioReturning(302, location: '/cdn/95293.ts?token=z')
          .let((d) => Playback.resolve(d, gateway));
      expect(t.url, 'https://api.example.com/cdn/95293.ts?token=z');
    });

    test('CDN over https also gets no token (Bearer is for our gateway only)', () async {
      final t = await _dioReturning(302, location: 'https://cdn.net/x.ts')
          .let((d) => Playback.resolve(d, gateway, accessToken: 'JWT'));
      expect(t.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('resolve — other cases', () {
    setUp(() => Playback.probeOverride = (_) async => true);
    tearDown(() {
      Playback.probeOverride = null;
      Playback.resetDeadHosts();
    });

    test('200 (no redirect): opens the gateway URL with its headers', () async {
      final t = await _dioReturning(200)
          .let((d) => Playback.resolve(d, gateway, accessToken: 'JWT'));
      expect(t.url, gateway.toString());
      expect(t.headers['User-Agent'], isNotNull);
      // The gateway is our host ⇒ Bearer is allowed here (HTTPS).
      expect(t.headers['Authorization'], 'Bearer JWT');
    });

    test('3xx without location → treated as failure, not silent success', () async {
      expect(
        () => _dioReturning(302).let((d) => Playback.resolve(d, gateway)),
        throwsA(isA<PlaybackResolveException>()),
      );
    });

    test('401/403 → auth exception (player is not opened)', () async {
      for (final code in [401, 403]) {
        try {
          await _dioReturning(code).let((d) => Playback.resolve(d, gateway));
          fail('expected an exception for $code');
        } on PlaybackResolveException catch (e) {
          expect(e.statusCode, code);
          expect(e.isAuth, isTrue);
        }
      }
    });

    test('502 → exception, but not an auth one', () async {
      try {
        await _dioReturning(502).let((d) => Playback.resolve(d, gateway));
        fail('expected an exception');
      } on PlaybackResolveException catch (e) {
        expect(e.statusCode, 502);
        expect(e.isAuth, isFalse);
      }
    });
  });

  group('dead CDN bypass — requests another address', () {
    setUp(Playback.resetDeadHosts);
    tearDown(() {
      Playback.probeOverride = null;
      Playback.resetDeadHosts();
    });

    /// Returns a different CDN address per request (as the real gateway does).
    Dio rotating(List<String> hosts) {
      var i = 0;
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((_) {
        final h = hosts[i++ % hosts.length];
        return ResponseBody.fromBytes(<int>[], 302, headers: {
          'location': ['http://$h:8080/live/0/0/1.ts?token=t']
        });
      });
      return dio;
    }

    test('first address dead, second alive ⇒ returns the live one', () async {
      Playback.probeOverride = (u) async => u.host == 'alive.cdn';
      final t = await Playback.resolve(
          rotating(['dead.cdn', 'alive.cdn']), gateway);
      expect(Uri.parse(t.url).host, 'alive.cdn');
    });

    test('three dead then one alive ⇒ reaches it', () async {
      Playback.probeOverride = (u) async => u.host == 'good.cdn';
      final t = await Playback.resolve(
          rotating(['d1.cdn', 'd2.cdn', 'd3.cdn', 'good.cdn']), gateway);
      expect(Uri.parse(t.url).host, 'good.cdn');
    });

    test('live address on first try ⇒ a single probe, no retry', () async {
      var probes = 0;
      Playback.probeOverride = (_) async {
        probes++;
        return true;
      };
      final t = await Playback.resolve(rotating(['ok.cdn']), gateway);
      expect(Uri.parse(t.url).host, 'ok.cdn');
      expect(probes, 1);
    });

    test('all dead ⇒ hands back the last one (the guard shows the failure), no throw', () async {
      Playback.probeOverride = (_) async => false;
      final t = await Playback.resolve(rotating(['x.cdn']), gateway);
      expect(t.url, contains('x.cdn'), reason: 'does not crash — lets the guard handle it');
    });

    test('🚀 a known dead host is skipped without a second probe', () async {
      var probes = 0;
      Playback.probeOverride = (u) async {
        probes++;
        return u.host == 'alive.cdn';
      };
      final dio = rotating(['dead.cdn', 'alive.cdn']);
      await Playback.resolve(dio, gateway); // discovers dead.cdn and remembers it
      final before = probes;
      await Playback.resolve(dio, gateway); // dead.cdn is skipped immediately
      expect(probes - before, lessThan(2),
          reason: 'we do not re-probe a host we know is dead');
    });

    test('🎯 a node whose **playback** failed is blocked — the probe cannot catch it', () async {
      // Accepts TCP (the probe passes it) but mpv fails on it ⇒ the player
      // reports markDead.
      Playback.probeOverride = (_) async => true;
      final dio = rotating(['bad-play.cdn', 'good.cdn']);

      final first = await Playback.resolve(dio, gateway);
      expect(Uri.parse(first.url).host, 'bad-play.cdn',
          reason: 'the probe passes it — it accepts the connection');

      // The player fails on it, so it blocks it.
      Playback.markDead('bad-play.cdn');

      final second = await Playback.resolve(dio, gateway);
      expect(Uri.parse(second.url).host, 'good.cdn',
          reason: 'a blocked node is skipped even if the gateway returns it');
    });

    test('a direct gateway response (200) is not probed', () async {
      var probes = 0;
      Playback.probeOverride = (_) async {
        probes++;
        return true;
      };
      final t = await _dioReturning(200).let((d) => Playback.resolve(d, gateway));
      expect(t.isGateway, isTrue);
      expect(probes, 0, reason: 'our host just responded');
    });
  });

  group('immediate retry — absorbs a broken connection', () {
    setUp(() => Playback.probeOverride = (_) async => true);
    tearDown(() {
      Playback.probeOverride = null;
      Playback.resetDeadHosts();
    });

    test('timeout then success ⇒ succeeds without the user seeing an error', () async {
      var calls = 0;
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((o) {
        calls++;
        if (calls == 1) {
          // The first attempt hits a broken connection → timeout.
          throw DioException.receiveTimeout(
              timeout: const Duration(seconds: 6), requestOptions: o);
        }
        return ResponseBody.fromBytes(<int>[], 302,
            headers: {
              'location': ['http://cdn.net/x.ts?token=t']
            });
      });

      final t = await Playback.resolve(dio, gateway);
      expect(t.url, 'http://cdn.net/x.ts?token=t');
      expect(calls, 2, reason: 'retried exactly once, immediately');
    });

    test('an explicit gateway response (403) is not retried — pointless', () async {
      var calls = 0;
      final dio = Dio();
      dio.httpClientAdapter = _FakeAdapter((o) {
        calls++;
        return ResponseBody.fromBytes(<int>[], 403);
      });

      await expectLater(
        () => Playback.resolve(dio, gateway),
        throwsA(isA<PlaybackResolveException>()),
      );
      expect(calls, 1, reason: '403 is a final answer, so we do not repeat it');
    });
  });

  group('sanitizeForLog — no secret is printed to the log', () {
    test('masks token in a real CDN URL', () {
      final s = Playback.sanitizeForLog(
          'http://31.56.41.21:8080/live/0/0/95383.ts?token=eyJhbGciOiJIUzI1NiJ9.SECRET');
      expect(s, 'http://31.56.41.21:8080/live/0/0/95383.ts?token=<redacted>');
      expect(s.contains('SECRET'), isFalse);
    });

    test('masks token and keeps the other parameters', () {
      expect(
        Playback.sanitizeForLog('http://c.net/x.ts?token=abc123&ext=ts'),
        'http://c.net/x.ts?token=<redacted>&ext=ts',
      );
    });

    test('URL without token is left unchanged', () {
      expect(Playback.sanitizeForLog('http://c.net/x.ts'), 'http://c.net/x.ts');
    });
  });

  group('headers — host guard', () {
    test('foreign host: no Bearer or signature, whatever token we pass', () {
      final h = Playback.headers(Uri.parse('http://cdn.example.net/x.ts'),
          accessToken: 'JWT');
      expect(h.containsKey('Authorization'), isFalse);
      expect(h.containsKey('X-Sig'), isFalse);
      expect(h['User-Agent'], isNotNull);
    });

    test('our host: Bearer is added', () {
      final h = Playback.headers(gateway, accessToken: 'JWT');
      expect(h['Authorization'], 'Bearer JWT');
    });
  });
}

/// Sugar for passing dio within a single expression.
extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
