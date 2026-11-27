import 'dart:convert';
import 'package:dio/dio.dart';

import '../core/config.dart';
import 'hmac.dart';
import 'hosts.dart';

/// Signs requests to our own hosts only and sets the custom User-Agent.
/// - HMAC is applied only to our configured domains and their subdomains.
/// - X-Ts = Unix seconds (a correct device clock is enough; server window 300s).
class HmacInterceptor extends Interceptor {
  HmacInterceptor({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  static const _signer = HmacSigner(AppConfig.hmacSecret);

  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) {
    if (isOurHost(options.uri.host) && AppConfig.hmacSecret.isNotEmpty) {
      final ts = (_clock().millisecondsSinceEpoch ~/ 1000).toString();
      final pq =
          options.uri.path + (options.uri.hasQuery ? '?${options.uri.query}' : '');
      final body = options.data == null
          ? const <int>[]
          : utf8.encode(jsonEncode(options.data));
      options.headers['X-Ts'] = ts;
      options.headers['X-Sig'] = _signer.sign(
        method: options.method,
        pathQuery: pq,
        tsSec: ts,
        body: body,
      );
    }
    options.headers['User-Agent'] = AppConfig.userAgent;
    handler.next(options);
  }
}
