import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

import 'watch_now_info.dart';

/// What a member is watching now (with their identity) — for the
/// "Watching now" cards.
class WatchingEntry {
  const WatchingEntry({required this.identity, required this.info});
  final String identity;
  final WatchNowInfo info;
}

/// Watch party — over the **LiveKit data channel** (no media on our servers).
///
/// - **Broadcast:** whoever is watching sends `WatchNowInfo` on
///   `topic: "watch"` periodically and on every change.
/// - **Receive:** we keep the latest state per member; a `{"stop":1}`
///   message means they left.
/// - **Follow:** the follower opens whatever the host opens, tracks their
///   position/pause, switches along with them,
///   and leaves on `stop`.
class WatchPartyManager extends ChangeNotifier {
  /// How often the state is broadcast while watching.
  static const _beat = Duration(seconds: 3);

  Room? _room;
  EventsListener<RoomEvent>? _listener;
  Timer? _timer;

  /// What each member is currently watching (identity → info).
  final Map<String, WatchNowInfo> _watching = {};

  /// Who we are currently following (identity) — null = nobody.
  String? _followingIdentity;

  /// Provider of the current state to broadcast (filled in by the player).
  WatchNowInfo Function()? _snapshot;

  /// Called when the followed member broadcasts new content/position — the
  /// player acts on it.
  void Function(WatchNowInfo info)? onFollowUpdate;

  /// Called when the followed member leaves (`stop`) → we leave with them.
  void Function()? onFollowStopped;

  List<WatchingEntry> get watching => [
        for (final e in _watching.entries)
          WatchingEntry(identity: e.key, info: e.value),
      ];

  String? get followingIdentity => _followingIdentity;
  bool get isFollowing => _followingIdentity != null;

  WatchNowInfo? infoOf(String identity) => _watching[identity];

  // ── Room binding ──────────────────────────────────────────────────────

  void attach(Room room) {
    if (identical(_room, room)) return;
    detach();
    _room = room;
    _listener = room.createListener()
      ..on<DataReceivedEvent>(_onData)
      ..on<ParticipantDisconnectedEvent>((e) {
        final id = e.participant.identity;
        _watching.remove(id);
        if (_followingIdentity == id) {
          _followingIdentity = null;
          onFollowStopped?.call();
        }
        notifyListeners();
      });
  }

  void detach() {
    _listener?.dispose();
    _listener = null;
    _room = null;
    stopBroadcast();
    _watching.clear();
    _followingIdentity = null;
    notifyListeners();
  }

  // ── Receiving ─────────────────────────────────────────────────────────

  void _onData(DataReceivedEvent e) {
    if (e.topic != WatchNowInfo.topic) return;
    final identity = e.participant?.identity;
    if (identity == null) return;

    final raw = utf8.decode(e.data, allowMalformed: true);
    final now = DateTime.now().millisecondsSinceEpoch;

    // The host left.
    if (WatchNowInfo.rawIsStop(raw)) {
      _watching.remove(identity);
      if (_followingIdentity == identity) {
        _followingIdentity = null;
        onFollowStopped?.call();
      }
      notifyListeners();
      return;
    }

    final info = WatchNowInfo.decode(raw, now);
    if (info == null) return;
    _watching[identity] = info;

    if (_followingIdentity == identity) {
      onFollowUpdate?.call(info); // switch / follow position / pause
    }
    notifyListeners();
  }

  // ── Following ─────────────────────────────────────────────────────────

  /// Start following a member — the player opens what they are watching
  /// right away.
  void follow(String identity) {
    final info = _watching[identity];
    if (info == null) return;
    _followingIdentity = identity;
    notifyListeners();
    onFollowUpdate?.call(info);
  }

  void unfollow() {
    _followingIdentity = null;
    notifyListeners();
  }

  // ── Broadcasting ──────────────────────────────────────────────────────

  /// Start broadcasting what I am watching. [snapshot] returns the player's
  /// current state.
  void startBroadcast(WatchNowInfo Function() snapshot) {
    _snapshot = snapshot;
    _timer?.cancel();
    _timer = Timer.periodic(_beat, (_) => pushNow());
    pushNow(); // right away, don't wait for the first tick
  }

  /// Send the state now (on play/pause/switch).
  void pushNow() {
    final snap = _snapshot;
    final room = _room;
    if (snap == null || room == null) return;
    _publish(snap().encode());
  }

  /// Stop broadcasting and tell the others we left (`{"stop":1}`).
  void stopBroadcast({bool notifyStop = false}) {
    _timer?.cancel();
    _timer = null;
    if (notifyStop && _room != null) _publish(WatchNowInfo.stopMessage());
    _snapshot = null;
  }

  void _publish(String payload) {
    try {
      _room?.localParticipant?.publishData(
        utf8.encode(payload),
        reliable: true,
        topic: WatchNowInfo.topic,
      );
    } catch (e) {
      debugPrint('WATCH publish err: $e');
    }
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
