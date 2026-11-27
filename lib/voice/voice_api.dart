import 'package:dio/dio.dart';
import '../core/config.dart';

/// Credentials for joining a LiveKit room — as returned by token-service.
class RoomCredentials {
  const RoomCredentials({
    required this.url,
    required this.token,
    required this.code,
    required this.name,
    required this.admin,
  });

  /// LiveKit URL — **comes only from the response**, never hard-coded.
  final String url;
  final String token;
  final String code;
  final String name;
  final bool admin;
}

/// Voice error codes — localized in the UI (voice_room_sheet), not here.
enum VoiceErrorCode {
  invalidResponse,
  network,
  kicked,
  notFound,
  unreachable,
  joinFailed,
  micDenied,
}

/// Voice service error — carries a code that the UI localizes.
class VoiceException implements Exception {
  const VoiceException(this.code);
  final VoiceErrorCode code;
  @override
  String toString() => 'VoiceException($code)';
}

/// Voice rooms service at [AppConfig.voiceUrl].
///
/// Uses the app's **shared dio**: the voice host is one of our domains, so
/// `HmacInterceptor` signs it (X-Ts/X-Sig) and `AuthInterceptor` adds the
/// Bearer token automatically. **No voice-specific signing.**
class VoiceApi {
  VoiceApi(this._dio);

  static const base = AppConfig.voiceUrl;

  final Dio _dio;

  /// Creates a room — the server generates the code and makes the creator
  /// admin. We don't send identity/metadata — the server derives both from the
  /// JWT.
  ///
  /// [avatar]: the avatar number **as a string without leading zeros** ("7",
  /// not "07" or 7) — the server stamps it into the token metadata (same as
  /// Android).
  Future<RoomCredentials> create({
    required String name,
    required int capacity,
    required String avatar,
  }) =>
      _post('/rooms/create',
          {'name': name, 'capacity': capacity, 'avatar': avatar});

  /// Join by code — the code is **always** trimmed and upper-cased.
  Future<RoomCredentials> join(String code, {required String avatar}) =>
      _post('/rooms/join',
          {'code': code.trim().toUpperCase(), 'avatar': avatar});

  /// Kick a member (admin) — permanent; the server remembers it. Success =
  /// 2xx only.
  Future<void> kick({required String code, required String identity}) =>
      _postVoid('/rooms/kick', {'code': code, 'identity': identity});

  /// End the room (admin). Success = 2xx only.
  Future<void> end(String code) => _postVoid('/rooms/end', {'code': code});

  // ── internal ──────────────────────────────────────────────────────────

  Future<RoomCredentials> _post(String path, Map<String, dynamic> body) async {
    final data = await _request(path, body);
    final j = (data is Map) ? data.cast<String, dynamic>() : const {};

    final url = '${j['url'] ?? ''}'.trim();
    final token = '${j['token'] ?? ''}'.trim();
    // Alternate key for the code: "room".
    final code = '${j['code'] ?? j['room'] ?? ''}'.trim();
    if (url.isEmpty || token.isEmpty || code.isEmpty) {
      throw const VoiceException(VoiceErrorCode.invalidResponse);
    }
    final name = '${j['name'] ?? ''}'.trim();
    return RoomCredentials(
      url: url,
      token: token,
      code: code,
      name: name.isEmpty ? code : name, // empty name → use the code
      admin: j['admin'] == true,
    );
  }

  Future<void> _postVoid(String path, Map<String, dynamic> body) async {
    await _request(path, body); // 2xx only — we don't decode the response
  }

  Future<dynamic> _request(String path, Map<String, dynamic> body) async {
    try {
      final r = await _dio.post(
        '$base$path',
        data: body,
        options: Options(
          contentType: 'application/json; charset=utf-8',
        ),
      );
      return r.data;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == null) {
        throw const VoiceException(VoiceErrorCode.network);
      }
      throw VoiceException(switch (code) {
        403 => VoiceErrorCode.kicked,
        404 => VoiceErrorCode.notFound,
        _ => VoiceErrorCode.unreachable,
      });
    }
  }
}
