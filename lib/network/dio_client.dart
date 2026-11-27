import 'package:dio/dio.dart';

import '../core/config.dart';
import 'auth_interceptor.dart';
import 'hmac_interceptor.dart';
import 'log_interceptor.dart';
import 'session_store.dart';

/// Central dio client — HMAC + Bearer/refresh + User-Agent, base URL from the
/// build config.
///
/// SSL pinning (SPKI) is added via `badCertificateCallback` on the adapter at
/// build time for iOS/Android (a future extension point — does not work on the
/// web).
class DioClient {
  DioClient._();

  static Dio create({
    required SessionStore session,
    required void Function() onSessionExpired,
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Accept': 'application/json'},
      ),
    );
    // The provider catalog is huge (20k+ movies, 8k channels) — decode JSON on
    // a background isolate instead of the main thread, otherwise the UI freezes
    // for seconds at startup.
    dio.transformer = BackgroundTransformer();

    dio.interceptors.add(HmacInterceptor());
    dio.interceptors.add(AuthInterceptor(
      session: session,
      baseUrl: AppConfig.baseUrl,
      onSessionExpired: onSessionExpired,
    ));
    dio.interceptors.add(AppLogInterceptor());
    return dio;
  }
}
