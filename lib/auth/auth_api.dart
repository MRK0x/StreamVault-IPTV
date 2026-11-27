import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../network/api_paths.dart';

/// A linked device (returned with 409 device limit).
class DeviceInfo {
  const DeviceInfo({required this.id, required this.name, this.lastSeen});
  final String id;
  final String name;
  final String? lastSeen;

  static DeviceInfo fromJson(Map<String, dynamic> j) => DeviceInfo(
        id: '${j['id'] ?? j['device_id'] ?? j['deviceId'] ?? ''}',
        name: '${j['name'] ?? j['device_name'] ?? j['model'] ?? ''}',
        lastSeen: j['last_seen']?.toString() ?? j['lastSeen']?.toString(),
      );
}

enum LoginStatus { success, deviceLimit, error }

/// Registration fields the server may return errors for (names as it sends them).
enum RegisterField { username, email, password }

enum RegisterStatus {
  success,

  /// 400 — detailed per-field validation errors.
  invalidFields,

  /// 429 — attempt limit exceeded (server: 5/hour).
  throttled,
  error,
}

/// Registration result — on success the response **matches the login shape**,
/// so we sign in directly.
class RegisterOutcome {
  const RegisterOutcome._(
    this.status, {
    this.access,
    this.refresh,
    this.username,
    this.fieldErrors = const {},
  });

  factory RegisterOutcome.success({
    required String access,
    required String refresh,
    String? username,
  }) =>
      RegisterOutcome._(RegisterStatus.success,
          access: access, refresh: refresh, username: username);

  factory RegisterOutcome.invalidFields(Map<RegisterField, String> errors) =>
      RegisterOutcome._(RegisterStatus.invalidFields, fieldErrors: errors);

  factory RegisterOutcome.throttled() =>
      const RegisterOutcome._(RegisterStatus.throttled);

  factory RegisterOutcome.failed() =>
      const RegisterOutcome._(RegisterStatus.error);

  final RegisterStatus status;
  final String? access;
  final String? refresh;
  final String? username;

  /// Per-field error — the value is the **raw server message**. Used in the UI
  /// as a display hint only; **logic relies on the field name, not its text**
  /// (per the contract).
  final Map<RegisterField, String> fieldErrors;
}

/// Auth error codes — localized in the UI (login_screen), not in this layer.
enum AuthErrorCode { emptyCredentials, badCredentials, network, deviceLimit, generic }

class LoginOutcome {
  const LoginOutcome._(this.status,
      {this.access, this.refresh, this.username, this.devices, this.errorCode});

  factory LoginOutcome.success(
          {required String access,
          required String refresh,
          String? username}) =>
      LoginOutcome._(LoginStatus.success,
          access: access, refresh: refresh, username: username);

  factory LoginOutcome.deviceLimit(List<DeviceInfo> devices) =>
      LoginOutcome._(LoginStatus.deviceLimit, devices: devices);

  factory LoginOutcome.error(AuthErrorCode code) =>
      LoginOutcome._(LoginStatus.error, errorCode: code);

  final LoginStatus status;
  final String? access;
  final String? refresh;
  final String? username;
  final List<DeviceInfo>? devices;
  final AuthErrorCode? errorCode;
}

/// Real authentication calls.
class AuthApi {
  AuthApi(this._dio);
  final Dio _dio;

  Future<LoginOutcome> login(
    String username,
    String password, {
    required String deviceId,
    String? deviceName,
    String? evictDeviceId,
  }) async {
    try {
      final data = <String, dynamic>{
        'username': username,
        'password': password,
        'device_id': deviceId, // JWT is bound to the device — required
        'device_name': ?deviceName,
        'evict_device_id': ?evictDeviceId,
      };

      final r = await _dio.post(ApiPaths.login, data: data);
      final body = r.data as Map<String, dynamic>;
      final user = body['user'];
      return LoginOutcome.success(
        access: body['access'] as String,
        refresh: body['refresh'] as String,
        username: (user is Map ? user['username']?.toString() : null) ?? username,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 409) {
        return LoginOutcome.deviceLimit(_parseDevices(e.response?.data));
      }
      return LoginOutcome.error(_errorCode(code));
    } catch (e) {
      return LoginOutcome.error(AuthErrorCode.generic);
    }
  }

  /// Register a new account — `POST /api/auth/register/` (no Bearer; the user is
  /// not signed in yet, and dio signs HMAC automatically).
  ///
  /// Success is **201** and its response matches the login shape ⇒ we store the
  /// tokens and sign in directly. The server details 400 errors **per field**;
  /// we pass them through as-is for the UI to localize.
  Future<RegisterOutcome> register({
    required String username,
    required String email,
    required String password,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      final r = await _dio.post(
        ApiPaths.register,
        data: <String, dynamic>{
          'username': username,
          'email': email,
          'password': password,
          'device_id': deviceId, // required — same ID as login (token is device-bound)
          'device_name': ?deviceName,
        },
        // Registration hashes the password on the server, so it is slower than
        // the other calls (~3s measured); the global 30s timeout is too tight
        // for it.
        options: Options(receiveTimeout: const Duration(seconds: 90)),
      );
      final body = (r.data as Map).cast<String, dynamic>();
      final user = body['user'];
      return RegisterOutcome.success(
        access: body['access'] as String,
        refresh: body['refresh'] as String,
        username:
            (user is Map ? user['username']?.toString() : null) ?? username,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      debugPrint('REG ✗ ${e.type} status=$code');
      if (code == 400) {
        final errors = _fieldErrors(e.response?.data);
        // 400 with no known fields (unexpected shape) → generic error, not a
        // silent screen.
        if (errors.isNotEmpty) return RegisterOutcome.invalidFields(errors);
        return RegisterOutcome.failed();
      }
      if (code == 429) return RegisterOutcome.throttled();
      return RegisterOutcome.failed();
    } catch (e) {
      debugPrint('REG ✗ unexpected: $e');
      return RegisterOutcome.failed();
    }
  }

  /// Converts `{"email":["..."],"password":["..."]}` into a map of field →
  /// first message. Any key we don't recognize is ignored (we don't invent
  /// fields).
  Map<RegisterField, String> _fieldErrors(dynamic data) {
    if (data is! Map) return const {};
    const known = {
      'username': RegisterField.username,
      'email': RegisterField.email,
      'password': RegisterField.password,
    };
    final out = <RegisterField, String>{};
    known.forEach((key, field) {
      final v = data[key];
      final msg = (v is List && v.isNotEmpty) ? v.first?.toString() : null;
      if (msg != null && msg.isNotEmpty) out[field] = msg;
    });
    return out;
  }

  Future<void> refresh(String refreshToken) =>
      _dio.post(ApiPaths.refresh, data: {'refresh': refreshToken});

  Future<Map<String, dynamic>> me() async {
    final r = await _dio.get(ApiPaths.me);
    return (r.data as Map).cast<String, dynamic>();
  }

  List<DeviceInfo> _parseDevices(dynamic data) {
    final list = (data is Map)
        ? (data['devices'] ?? data['sessions'] ?? data['data'])
        : data;
    if (list is List) {
      return list
          .whereType<Map>()
          .map((e) => DeviceInfo.fromJson(e.cast<String, dynamic>()))
          .toList();
    }
    return const [];
  }

  /// Classifies a login error into a code the UI localizes (no Arabic text here).
  AuthErrorCode _errorCode(int? code) {
    if (code == 401 || code == 400) return AuthErrorCode.badCredentials;
    if (code == null) return AuthErrorCode.network;
    return AuthErrorCode.generic;
  }
}
