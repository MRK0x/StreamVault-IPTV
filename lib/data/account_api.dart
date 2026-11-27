import 'package:dio/dio.dart';

import '../network/api_paths.dart';
import 'models/account.dart';

/// Result of redeeming a subscription coupon.
enum RedeemStatus {
  success,

  /// 400 — invalid or already-used code.
  invalidCode,

  /// 429 — too many attempts (server: 10/hour).
  throttled,
  error,
}

/// The user's account and devices — contracts confirmed against the server
/// itself (OPTIONS probe):
/// - `GET /api/me/`            → user + device + subscription
/// - `GET /api/devices/`       → «Device List — the authenticated user's active devices»
/// - `DELETE /api/devices/{id}/` → «Device Delete — evict one of the user's own devices
///                                  (frees a slot, revokes its tokens)»
class AccountApi {
  AccountApi(this._dio);

  final Dio _dio;

  Future<Account> me() async {
    final r = await _dio.get(ApiPaths.me);
    return Account.fromJson((r.data as Map).cast<String, dynamic>());
  }

  Future<List<UserDevice>> devices() async {
    final r = await _dio.get(ApiPaths.devices);
    final list = r.data;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((e) => UserDevice.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Evicts a device (frees a slot and revokes its tokens). Success = 2xx.
  Future<void> evictDevice(int id) => _dio.delete(ApiPaths.device(id));

  /// Redeems a subscription coupon — `POST /api/subscriptions/redeem/`
  /// (requires Bearer).
  ///
  /// The server matches the code with `code.strip()` **and is case-sensitive**;
  /// but codes are generated from an upper-case-only alphabet, so upper-casing
  /// in the UI is safe.
  ///
  /// Its response (SubscriptionSerializer) differs from the `/api/me/` shape,
  /// so we don't map it here — the caller reloads `/api/me/` to keep a single
  /// source of truth for subscription state.
  Future<RedeemStatus> redeem(String code) async {
    try {
      await _dio.post(ApiPaths.redeem, data: {'code': code.trim()});
      return RedeemStatus.success;
    } on DioException catch (e) {
      // Logic keys off the status code, not the English `detail` text.
      return switch (e.response?.statusCode) {
        400 => RedeemStatus.invalidCode,
        429 => RedeemStatus.throttled,
        _ => RedeemStatus.error,
      };
    } catch (_) {
      return RedeemStatus.error;
    }
  }
}
