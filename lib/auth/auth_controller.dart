import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config.dart';
import '../network/session_store.dart';
import 'auth_api.dart';
import 'auth_state.dart';

/// Authentication controller.
/// - Demo mode (mock): a test login that succeeds with any credentials.
/// - Real mode: `/api/auth/login/` via [AuthApi] + JWT stored in the
///   Keychain + 409 device limit.
class AuthController extends StateNotifier<AuthState> {
  AuthController({required this.session, required this.api})
      : super(const AuthState());

  final SessionStore session;
  final AuthApi api;

  // Credentials of the current attempt (in memory) — used to log in again
  // after signing a device out (409).
  String? _pendingUser;
  String? _pendingPass;

  /// Restore the session on startup.
  Future<void> restore() async {
    await session.load();
    if (session.hasSession) {
      state = state.copyWith(
        status: AuthStatus.authenticated,
        username: session.username,
      );
    } else {
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
  }

  Future<void> login(String username, String password,
      {String? evictDeviceId}) async {
    final u = username.trim();
    if (u.isEmpty || password.isEmpty) {
      state = state.copyWith(
        status: AuthStatus.unauthenticated,
        errorCode: AuthErrorCode.emptyCredentials,
        devices: const [],
      );
      return;
    }

    _pendingUser = u;
    _pendingPass = password;

    state = state.copyWith(
        status: AuthStatus.authenticating, errorCode: null, devices: const []);

    // Demo mode
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await session.saveTokens(access: 'demo-token', refresh: 'demo-refresh');
      await session.saveCredentials(u, password);
      state = AuthState(status: AuthStatus.authenticated, username: u);
      return;
    }

    // Real mode
    final outcome = await api.login(
      u,
      password,
      deviceId: await session.deviceId(),
      deviceName: _deviceName,
      evictDeviceId: evictDeviceId,
    );
    switch (outcome.status) {
      case LoginStatus.success:
        await session.saveTokens(
            access: outcome.access!, refresh: outcome.refresh!);
        await session.saveCredentials(u, password);
        state = AuthState(
            status: AuthStatus.authenticated,
            username: outcome.username ?? u);
      case LoginStatus.deviceLimit:
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorCode: AuthErrorCode.deviceLimit,
          devices: outcome.devices ?? const [],
        );
      case LoginStatus.error:
        state = state.copyWith(
          status: AuthStatus.unauthenticated,
          errorCode: outcome.errorCode ?? AuthErrorCode.generic,
          devices: const [],
        );
    }
  }

  /// Register a new account, then **log in directly** — the server response
  /// matches the login payload, so we follow the same session path and don't
  /// ask the user to log in a second time.
  ///
  /// Returns the result to the UI so it can show each field's errors under it.
  Future<RegisterOutcome> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final u = username.trim();
    final e = email.trim();

    state = state.copyWith(
        status: AuthStatus.authenticating, errorCode: null, devices: const []);

    // Demo mode: succeeds with any credentials (like login).
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 600));
      await session.saveTokens(access: 'demo-token', refresh: 'demo-refresh');
      await session.saveCredentials(u, password);
      state = AuthState(status: AuthStatus.authenticated, username: u);
      return RegisterOutcome.success(
          access: 'demo-token', refresh: 'demo-refresh', username: u);
    }

    final outcome = await api.register(
      username: u,
      email: e,
      password: password,
      // **Same** device ID as login — the token is bound to the device, and a
      // different one breaks the session.
      deviceId: await session.deviceId(),
      deviceName: _deviceName,
    );

    if (outcome.status == RegisterStatus.success) {
      _pendingUser = u;
      _pendingPass = password;
      await session.saveTokens(
          access: outcome.access!, refresh: outcome.refresh!);
      await session.saveCredentials(u, password);
      state = AuthState(
          status: AuthStatus.authenticated, username: outcome.username ?? u);
    } else {
      // Errors are shown on the registration screen under their fields, not
      // as a generic error here.
      state = state.copyWith(status: AuthStatus.unauthenticated);
    }
    return outcome;
  }

  /// Sign a device out, then retry login (uses the current attempt's
  /// credentials or the saved ones).
  Future<void> evictAndRetry(String deviceId) async {
    final u = _pendingUser ?? session.username;
    final p = _pendingPass ?? await session.readPassword();
    if (u == null || p == null) return;
    await login(u, p, evictDeviceId: deviceId);
  }

  /// Friendly device name shown in the device list.
  String get _deviceName => switch (defaultTargetPlatform) {
        TargetPlatform.iOS => 'iPhone • MRK0sLivE',
        TargetPlatform.android => 'Android • MRK0sLivE',
        _ => 'MRK0sLivE',
      };

  /// Called from the auth interceptor when refresh fails (a 401 that isn't a
  /// signature error).
  void onSessionExpired() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> logout() async {
    await session.clearAll();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}
