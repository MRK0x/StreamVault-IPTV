import 'dart:convert';

/// Voice-room avatar — **a literal port of `VoiceAvatar` from the Android
/// source**.
///
/// Both platforms share the same rooms, so any drift here = an iPhone member
/// shows the wrong picture to an Android member. Don't change anything
/// without matching Android.
///
/// **The client never writes metadata**: the server bakes it into the LiveKit
/// token from the `avatar` field sent in create/join, so it's fixed for the
/// whole session (a new choice applies to the next room). Calling
/// `setMetadata` from the client breaks compatibility.
class VoiceAvatar {
  VoiceAvatar._();

  static const int defaultIndex = 0;
  static const int schemaVersion = 1;

  /// Number of images — matches assets/avatars/avatar_00..avatar_20.
  static const int count = 21;

  /// Asset path for an index: 7 → assets/avatars/avatar_07.webp
  /// (zero-padding is in **the file name only**; the wire value is unpadded).
  static String assetOf(int index) =>
      'assets/avatars/avatar_${normalize(index).toString().padLeft(2, '0')}.webp';

  /// Clamps the index to 0..20, otherwise the default.
  static int normalize(int index) =>
      (index >= 0 && index < count) ? index : defaultIndex;

  /// Converts a raw value (string/number) to a valid index — matches
  /// Android's leniency:
  /// " 7 ", "07" and 7 all → 7; empty/malformed → 0.
  static int normalizeRaw(Object? raw) =>
      normalize(int.tryParse(_optString(raw).trim()) ?? defaultIndex);

  /// Parses a participant's metadata into (admin?, avatar index).
  ///
  /// **Never throws**: any empty or malformed metadata yields the default
  /// (0, false) — the member is always shown, never dropped.
  ///
  /// Schema: `{"v":1,"av":"<0-20>","adm":true|false}`
  /// ⚠️ A `v` other than 1 drops **both the avatar and the badge** (matches
  /// Android).
  static ({bool isAdmin, int avatar}) parseMetadata(String? raw) {
    const fallback = (isAdmin: false, avatar: defaultIndex);
    if (raw == null || raw.trim().isEmpty) return fallback;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return fallback;
      final o = decoded.cast<String, dynamic>();
      if (_optInt(o['v'], 0) != schemaVersion) return fallback;
      return (
        isAdmin: _optBool(o['adm'], false),
        avatar: normalizeRaw(o['av']),
      );
    } catch (_) {
      return fallback; // malformed JSON — show the member with the default
    }
  }

  // ── Emulating Android's org.json leniency (Dart is stricter) ─────────

  /// Equivalent of `JSONObject.optString`: missing → '', integer 7 → '7',
  /// and double 7.0 → '7.0' (so parsing fails and yields the default — as on
  /// Android).
  static String _optString(Object? v) {
    if (v == null) return '';
    if (v is String) return v;
    if (v is int) return v.toString();
    return v.toString();
  }

  /// Equivalent of `JSONObject.optInt`: accepts 1, "1" and 1.0.
  static int _optInt(Object? v, int fallback) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  /// Equivalent of `JSONObject.optBoolean`: accepts true and "true".
  static bool _optBool(Object? v, bool fallback) {
    if (v is bool) return v;
    if (v is String) {
      final s = v.trim().toLowerCase();
      if (s == 'true') return true;
      if (s == 'false') return false;
    }
    return fallback;
  }
}
