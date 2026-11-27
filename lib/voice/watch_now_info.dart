import 'dart:convert';

import '../data/models/media_item.dart';

/// "What am I watching now" message over the LiveKit data channel — follows
/// the agreed schema exactly.
///
/// ```jsonc
/// // topic: "watch"
/// { "v":1, "kind":"live|movie|series",
///   "sid":<stream_id>,                                    // live/movie
///   "ser":<series_id>, "sn":<season>, "ep":<episode>, "eid":<episode_id>, // series
///   "t":"Title", "img":"https://.../poster.jpg",
///   "pos":<positionMs>, "dur":<durationMs>, "play":true, "live":false, "ts":<sentAtMs> }
/// // Exit message:
/// { "stop":1 }
/// ```
///
/// Keys are short on purpose (message size), and the IDs are the **stable
/// provider IDs** so the content can be resolved on any other device.
class WatchNowInfo {
  const WatchNowInfo({
    required this.kind,
    this.streamId,
    this.seriesId,
    this.season,
    this.episode,
    this.episodeId,
    required this.title,
    this.image,
    required this.positionMs,
    this.durationMs,
    required this.playing,
    required this.isLive,
    required this.sentAtMs,
    this.receivedAtMs,
  });

  static const version = 1;
  static const topic = 'watch';

  final MediaKind kind;

  /// live/movie — provider ID.
  final String? streamId;

  // series
  final String? seriesId;
  final int? season;
  final int? episode;
  final String? episodeId;

  final String title;
  final String? image;
  final int positionMs;
  final int? durationMs;
  final bool playing;
  final bool isLive;

  /// Sender's clock (never compared with ours — only used for relative
  /// extrapolation).
  final int sentAtMs;

  /// **Receiver's** clock at the moment of receipt (extrapolate on the member's
  /// clock only).
  final int? receivedAtMs;

  // ── Serialization ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'v': version,
        'kind': switch (kind) {
          MediaKind.live => 'live',
          MediaKind.movie => 'movie',
          MediaKind.series => 'series',
        },
        'sid': ?streamId,
        'ser': ?seriesId,
        'sn': ?season,
        'ep': ?episode,
        'eid': ?episodeId,
        't': title,
        'img': ?image,
        'pos': positionMs,
        'dur': ?durationMs,
        'play': playing,
        'live': isLive,
        'ts': sentAtMs,
      };

  String encode() => jsonEncode(toMap());

  /// Host exit message.
  static String stopMessage() => jsonEncode({'stop': 1});

  static bool isStop(Map<String, dynamic> j) => j['stop'] == 1;

  /// [receivedAt] = receiving device's clock on arrival (for extrapolation).
  static WatchNowInfo? fromMap(Map<String, dynamic> j, int receivedAt) {
    if (isStop(j)) return null;
    final k = '${j['kind']}';
    final kind = switch (k) {
      'live' => MediaKind.live,
      'series' => MediaKind.series,
      _ => MediaKind.movie,
    };
    return WatchNowInfo(
      kind: kind,
      streamId: _str(j['sid']),
      seriesId: _str(j['ser']),
      season: _int(j['sn']),
      episode: _int(j['ep']),
      episodeId: _str(j['eid']),
      title: '${j['t'] ?? ''}',
      image: _str(j['img']),
      positionMs: _int(j['pos']) ?? 0,
      durationMs: _int(j['dur']),
      playing: j['play'] == true,
      isLive: j['live'] == true,
      sentAtMs: _int(j['ts']) ?? 0,
      receivedAtMs: receivedAt,
    );
  }

  static WatchNowInfo? decode(String raw, int receivedAt) {
    try {
      final j = jsonDecode(raw);
      if (j is! Map) return null;
      return fromMap(j.cast<String, dynamic>(), receivedAt);
    } catch (_) {
      return null;
    }
  }

  /// Is the raw message an exit message?
  static bool rawIsStop(String raw) {
    try {
      final j = jsonDecode(raw);
      return j is Map && isStop(j.cast<String, dynamic>());
    } catch (_) {
      return false;
    }
  }

  // ── Follow logic ──────────────────────────────────────────────────────

  /// Start position when joining (VOD only):
  /// `seek = pos + (nowMember - receivedAtMember)` — **member's clock only**,
  /// to compensate for the delay since receipt (we never compare our clock
  /// with the sender's).
  Duration seekTarget({int? nowMs}) {
    if (isLive) return Duration.zero;
    final now = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final drift = (receivedAtMs == null || !playing) ? 0 : (now - receivedAtMs!);
    var ms = positionMs + (drift < 0 ? 0 : drift);
    if (durationMs != null && ms > durationMs!) ms = durationMs!;
    return Duration(milliseconds: ms);
  }

  /// Content identity — to detect "did the host switch?".
  String get contentKey => switch (kind) {
        MediaKind.series => 'series:${episodeId ?? "$seriesId-$season-$episode"}',
        MediaKind.live => 'live:$streamId',
        MediaKind.movie => 'movie:$streamId',
      };

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = '$v'.trim();
    return s.isEmpty ? null : s;
  }

  static int? _int(dynamic v) =>
      v == null ? null : (v is int ? v : int.tryParse('$v'));
}
