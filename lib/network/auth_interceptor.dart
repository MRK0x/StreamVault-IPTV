import 'package:dio/dio.dart';

import 'api_paths.dart';
import 'hmac_interceptor.dart';
import 'hosts.dart';
import 'session_store.dart';

/// Authentication interceptor:
/// - Adds `Authorization: Bearer <access>` to requests to our hosts (except
///   login/register/refresh).
/// - On 401 (not signature-related): refreshes the token once and retries the
///   request; if refresh fails → end the session.
/// - On a **signature** 403 (`X-HMAC-Reject` header): does **not** log out (a
///   transient signing error).
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.session,
    required String baseUrl,
    required this.onSessionExpired,
  }) : _refreshDio = Dio(BaseOptions(baseUrl: baseUrl)) {
    _refreshDio.interceptors.add(HmacInterceptor());
  }

  final SessionStore session;
  final void Function() onSessionExpired;
  final Dio _refreshDio;

  static const _authPaths = {
    ApiPaths.login,
    ApiPaths.register,
    ApiPaths.refresh,
  };

  bool _isAuthPath(String path) => _authPaths.any(path.contains);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = session.access;
    if (isOurHost(options.uri.host) &&
        token != null &&
        token.isNotEmpty &&
        !_isAuthPath(options.path)) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final response = err.response;
    final status = response?.statusCode;

    // 403 HMAC signature — don't log out.
    final hmacReject = response?.headers.value('X-HMAC-Reject') != null ||
        response?.headers.value('x-hmac-reject') != null;
    if (status == 403 && hmacReject) {
      return handler.next(err);
    }

    final req = err.requestOptions;

    // An expired token gets **403** on the stream path and 401 on the API
    // surface, so we accept both. (Signature 403 was excluded above, so what
    // remains here is auth.)
    final expiredToken = status == 401 || status == 403;
    final canRefresh = expiredToken &&
        !_isAuthPath(req.path) &&
        (session.refresh?.isNotEmpty ?? false) &&
        req.extra['__retried'] != true;

    if (!canRefresh) {
      return handler.next(err);
    }

    // -- (1) Refresh: only its failure means the session has really ended --
    final String newAccess;
    try {
      final r = await _refreshDio.post(
        ApiPaths.refresh,
        data: {'refresh': session.refresh},
      );
      final access = (r.data is Map) ? r.data['access'] as String? : null;
      if (access == null || access.isEmpty) {
        throw StateError('no access in refresh');
      }
      newAccess = access;
      await session.updateAccess(newAccess);
    } catch (_) {
      await session.clear();
      onSessionExpired();
      return handler.next(err);
    }

    // -- (2) Retry the request with the new token (once) --
    // ⚠️ A failure here is **not** a reason to log out: the refresh worked,
    // so the session is fine. E.g. a blocked channel returns 403 again — pass
    // the error through and don't kick the user out.
    try {
      req.extra['__retried'] = true;
      req.headers['Authorization'] = 'Bearer $newAccess';
      final retryDio =
          Dio(BaseOptions(baseUrl: '${req.uri.scheme}://${req.uri.host}'));
      retryDio.interceptors.add(HmacInterceptor());
      final clone = await retryDio.fetch(req);
      return handler.resolve(clone);
    } on DioException catch (e) {
      return handler.next(e);
    } catch (_) {
      return handler.next(err);
    }
  }
}
