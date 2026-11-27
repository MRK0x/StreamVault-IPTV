import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/data/account_api.dart';
import 'package:mrk0slive/data/models/account.dart';

/// Locks down the redeem contract extracted from the server source
/// (subscriptions/views.py RedeemView + services.redeem_code).
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);
  final ResponseBody Function(RequestOptions o) respond;

  @override
  Future<ResponseBody> fetch(RequestOptions options,
          Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async =>
      respond(options);

  @override
  void close({bool force = false}) {}
}

AccountApi _apiReturning(int code, Object body,
    {void Function(RequestOptions)? spy}) {
  final dio = Dio();
  dio.httpClientAdapter = _FakeAdapter((o) {
    spy?.call(o);
    return ResponseBody.fromBytes(
      utf8.encode(jsonEncode(body)),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  });
  return AccountApi(dio);
}

void main() {
  // The actual SubscriptionSerializer response shape.
  const subBody = {
    'id': 7,
    'plan': {'id': 2, 'name': 'Duo'},
    'is_active': true,
    'is_valid': true,
    'start_date': '2026-07-17T00:00:00Z',
    'expiry_date': '2026-08-17T00:00:00Z',
    'created_at': '2026-07-17T00:00:00Z',
  };

  group('redeem — success', () {
    test('201 → success', () async {
      expect(await _apiReturning(201, subBody).redeem('Q6LR-YVFB-PYD5'),
          RedeemStatus.success);
    });

    test('🔑 sends the code under the "code" key and trims whitespace', () async {
      RequestOptions? sent;
      await _apiReturning(201, subBody, spy: (o) => sent = o)
          .redeem('  Q6LR-YVFB-PYD5  ');
      expect((sent!.data as Map)['code'], 'Q6LR-YVFB-PYD5',
          reason: 'the server matches with code.strip()');
      expect(sent!.path, '/api/subscriptions/redeem/');
    });
  });

  group('redeem — failure (keyed on status code, not detail text)', () {
    test('400 → invalidCode whatever the detail text', () async {
      for (final detail in [
        'Invalid or already-used code.',
        'أي نصّ آخر',
        '',
      ]) {
        expect(await _apiReturning(400, {'detail': detail}).redeem('X'),
            RedeemStatus.invalidCode,
            reason: detail);
      }
    });

    test('429 → throttled (server: 10/hour)', () async {
      expect(
          await _apiReturning(429, {'detail': 'throttled'}).redeem('X'),
          RedeemStatus.throttled);
    });

    test('401 → generic error (not treated as a wrong code)', () async {
      expect(await _apiReturning(401, {'detail': 'no auth'}).redeem('X'),
          RedeemStatus.error);
    });

    test('500 → generic error', () async {
      expect(await _apiReturning(500, {'detail': 'boom'}).redeem('X'),
          RedeemStatus.error);
    });
  });

  group('Subscription.never — new account ≠ expired subscription', () {
    Subscription parse(Map<String, dynamic> j) => Subscription.fromJson(j);

    test('new account after sign-up → never', () {
      final s = parse({'active': false, 'plan': null, 'expiry_date': null});
      expect(s.never, isTrue);
    });

    test('expired subscription (has a date) → not never', () {
      final s = parse({
        'active': false,
        'plan': 'Duo',
        'expiry_date': '2020-01-01T00:00:00Z',
      });
      expect(s.never, isFalse);
      expect(s.expired, isTrue);
    });

    test('active subscription → neither never nor expired', () {
      final s = parse({
        'active': true,
        'plan': 'Duo',
        'expiry_date': '2099-01-01T00:00:00Z',
      });
      expect(s.never, isFalse);
      expect(s.expired, isFalse);
    });
  });
}
