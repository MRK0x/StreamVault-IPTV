import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

/// Session store — JWT tokens + credentials + device id, in memory + Keychain.
/// The auth interceptor reads the token from it synchronously (no I/O per
/// request).
class SessionStore {
  SessionStore(this._storage);

  final FlutterSecureStorage _storage;

  static const _kAccess = 'access';
  static const _kRefresh = 'refresh';
  static const _kUsername = 'username';
  static const _kPassword = 'password'; // saved credentials
  static const _kDeviceId = 'device_id'; // stable device id (JWT is device-bound)

  String? _access;
  String? _refresh;
  String? _username;
  String? _deviceId;

  String? get access => _access;
  String? get refresh => _refresh;
  String? get username => _username;
  bool get hasSession => (_access?.isNotEmpty ?? false);

  /// Stable device id (generated once and persisted) — sent with login and
  /// used for the device limit.
  Future<String> deviceId() async {
    if (_deviceId?.isNotEmpty ?? false) return _deviceId!;
    try {
      _deviceId = await _storage.read(key: _kDeviceId);
    } catch (_) {}
    if (_deviceId == null || _deviceId!.isEmpty) {
      _deviceId = const Uuid().v4();
      await _write(_kDeviceId, _deviceId!);
    }
    return _deviceId!;
  }

  /// Load from the Keychain at startup.
  Future<void> load() async {
    try {
      _access = await _storage.read(key: _kAccess);
      _refresh = await _storage.read(key: _kRefresh);
      _username = await _storage.read(key: _kUsername);
      _deviceId = await _storage.read(key: _kDeviceId);
    } catch (_) {
      // Secure storage unavailable (e.g. an experimental web build).
    }
  }

  Future<void> saveTokens({required String access, required String refresh}) async {
    _access = access;
    _refresh = refresh;
    await _write(_kAccess, access);
    await _write(_kRefresh, refresh);
  }

  /// Update the access token only (after a refresh).
  Future<void> updateAccess(String access) async {
    _access = access;
    await _write(_kAccess, access);
  }

  Future<void> saveCredentials(String username, String password) async {
    _username = username;
    await _write(_kUsername, username);
    await _write(_kPassword, password);
  }

  Future<String?> readPassword() async {
    try {
      return await _storage.read(key: _kPassword);
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    _access = null;
    _refresh = null;
    // Keep the username/password for saved credentials except on an
    // explicit logout.
    for (final k in [_kAccess, _kRefresh]) {
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
  }

  Future<void> clearAll() async {
    _access = null;
    _refresh = null;
    _username = null;
    for (final k in [_kAccess, _kRefresh, _kUsername, _kPassword]) {
      try {
        await _storage.delete(key: k);
      } catch (_) {}
    }
  }

  Future<void> _write(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {}
  }
}
