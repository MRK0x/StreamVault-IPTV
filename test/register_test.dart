import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/auth/auth_api.dart';

/// Locks down the registration contract extracted from the server source
/// (accounts/views.py + serializers).
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

AuthApi _apiReturning(int code, Object body, {void Function(RequestOptions)? spy}) {
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
  return AuthApi(dio);
}

Future<RegisterOutcome> _register(AuthApi api) => api.register(
      username: 'sami',
      email: 'sami@example.com',
      password: 'Str0ng-Passw0rd!',
      deviceId: 'UUID-1',
      deviceName: 'iPhone',
    );

void main() {
  const okBody = {
    'access': 'ACCESS-TOKEN',
    'refresh': 'REFRESH-TOKEN',
    'user': {'id': 1, 'username': 'sami', 'email': 'sami@example.com'},
    'device': {'id': 1, 'device_id': 'UUID-1'},
    'subscription': {'active': false, 'plan': null},
  };

  group('201 success — response matches login', () {
    test('captures access/refresh/username', () async {
      final r = await _register(_apiReturning(201, okBody));
      expect(r.status, RegisterStatus.success);
      expect(r.access, 'ACCESS-TOKEN');
      expect(r.refresh, 'REFRESH-TOKEN');
      expect(r.username, 'sami');
    });

    test('🔑 sends device_id (required) and the device name', () async {
      RequestOptions? sent;
      await _register(_apiReturning(201, okBody, spy: (o) => sent = o));
      final body = (sent!.data as Map).cast<String, dynamic>();
      expect(body['device_id'], 'UUID-1', reason: 'the token is bound to the device');
      expect(body['device_name'], 'iPhone');
      expect(body['username'], 'sami');
      expect(body['email'], 'sami@example.com');
      expect(body['password'], 'Str0ng-Passw0rd!');
    });

    test('no Bearer — the user is not registered yet', () async {
      RequestOptions? sent;
      await _register(_apiReturning(201, okBody, spy: (o) => sent = o));
      expect(sent!.headers.containsKey('Authorization'), isFalse);
    });
  });

  group('400 — detailed per-field errors', () {
    test('username taken → error on the username field only', () async {
      final r = await _register(_apiReturning(
          400, {'username': ['Username already taken.']}));
      expect(r.status, RegisterStatus.invalidFields);
      expect(r.fieldErrors[RegisterField.username], 'Username already taken.');
      expect(r.fieldErrors.containsKey(RegisterField.email), isFalse);
    });

    test('email already registered → email field', () async {
      final r = await _register(
          _apiReturning(400, {'email': ['Email already registered.']}));
      expect(r.fieldErrors[RegisterField.email], 'Email already registered.');
    });

    test('weak password → password field', () async {
      final r = await _register(_apiReturning(400, {
        'password': ['This password is too common.']
      }));
      expect(r.fieldErrors[RegisterField.password], 'This password is too common.');
    });

    test('multiple errors at once', () async {
      final r = await _register(_apiReturning(400, {
        'username': ['Username already taken.'],
        'password': ['This password is entirely numeric.'],
      }));
      expect(r.fieldErrors.length, 2);
      expect(r.fieldErrors[RegisterField.username], isNotNull);
      expect(r.fieldErrors[RegisterField.password], isNotNull);
    });

    test('unknown keys are ignored (we don\'t invent fields)', () async {
      final r = await _register(
          _apiReturning(400, {'device_id': ['This field is required.']}));
      // No known field ⇒ a generic error, not a silent screen.
      expect(r.status, RegisterStatus.error);
    });

    test('unexpected 400 shape → generic error', () async {
      final r = await _register(_apiReturning(400, {'detail': 'nope'}));
      expect(r.status, RegisterStatus.error);
    });
  });

  group('other cases', () {
    test('429 → throttled (server: 5/hour)', () async {
      final r = await _register(_apiReturning(
          429, {'detail': 'Request was throttled.'}));
      expect(r.status, RegisterStatus.throttled);
    });

    test('500 → generic error', () async {
      final r = await _register(_apiReturning(500, {'detail': 'boom'}));
      expect(r.status, RegisterStatus.error);
    });
  });
}
