import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Compact network logger (debug only) — for checking the HMAC handshake and
/// responses.
/// Doesn't print full bodies or the secret; prints only the derived signature
/// (not sensitive).
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      final signed = options.headers.containsKey('X-Sig') ? '🔏' : '  ';
      final auth = options.headers.containsKey('Authorization') ? '🔑' : '  ';
      debugPrint('NET → ${options.method} ${options.path} $signed$auth');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      final n = response.data is List
          ? '(${(response.data as List).length} items)'
          : (response.data is Map ? '(map)' : '');
      debugPrint(
          'NET ← ${response.statusCode} ${response.requestOptions.path} $n');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      final code = err.response?.statusCode;
      final hmac = err.response?.headers.value('X-HMAC-Reject') != null
          ? ' [X-HMAC-Reject]'
          : '';
      debugPrint('NET ✗ $code ${err.requestOptions.path}$hmac — ${err.message}');
    }
    handler.next(err);
  }
}
