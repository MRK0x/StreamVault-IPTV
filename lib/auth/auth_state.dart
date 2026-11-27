import 'auth_api.dart';

/// Authentication state (device-bound JWT).
enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

class AuthState {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.username,
    this.errorCode,
    this.devices = const [],
  });

  final AuthStatus status;
  final String? username;

  /// Error code (localized in the UI). null = no error.
  final AuthErrorCode? errorCode;

  /// Linked devices shown on 409 (device limit) to pick one to sign out.
  final List<DeviceInfo> devices;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isBusy => status == AuthStatus.authenticating;
  bool get hasDeviceLimit => devices.isNotEmpty;

  AuthState copyWith({
    AuthStatus? status,
    String? username,
    AuthErrorCode? errorCode,
    List<DeviceInfo>? devices,
  }) =>
      AuthState(
        status: status ?? this.status,
        username: username ?? this.username,
        errorCode: errorCode,
        devices: devices ?? this.devices,
      );
}
