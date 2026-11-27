import 'dart:convert';
import 'package:crypto/crypto.dart';

/// HMAC signature — matches the server exactly:
///   Canonical = METHOD\npath(?query)\n{X-Ts}\n{sha256(body)}
///   X-Sig     = hex(HMAC_SHA256(secret, canonical))
/// body is empty for anything other than POST/PUT/PATCH.
class HmacSigner {
  const HmacSigner(this.secret);

  final String secret;

  String sign({
    required String method,
    required String pathQuery,
    required String tsSec,
    required List<int> body,
  }) {
    final bodyHash = sha256.convert(body).toString();
    final canonical = '$method\n$pathQuery\n$tsSec\n$bodyHash';
    return Hmac(sha256, utf8.encode(secret))
        .convert(utf8.encode(canonical))
        .toString();
  }
}
