import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';

import 'voice_api.dart';
import 'voice_avatar.dart';
import 'voice_room_state.dart';

/// Voice room manager — LiveKit via the token service.
///
/// Binding rules from the contract:
/// - The LiveKit URL comes in the create/join **response** (never hard-coded).
/// - **The mic is always muted on join.**
/// - Kick/end go through **our server**; the client never touches RoomService.
///
/// Note on "admin" — two separate kinds that must not be mixed (same as Android):
/// - `state.isAdmin` from the response's `admin` field ⇒ **my own permissions only**
///   (showing the kick/end buttons). Never used to draw a badge.
/// - `RoomMember.isAdmin` from **each member's** metadata ⇒ **the admin badge**,
///   so everyone sees it on the host, not just the host.
class VoiceRoomManager extends StateNotifier<VoiceRoomState> {
  VoiceRoomManager(this._api, {required int Function() readAvatar})
      // ignore: prefer_initializing_formals — Dart forbids `_`-prefixed named params
      : _readAvatar = readAvatar,
        super(const VoiceRoomState());

  final VoiceApi _api;

  /// Locally chosen avatar — read at join time (like `myAvatar()` on Android).
  final int Function() _readAvatar;

  /// The avatar we join with: text without leading zeros ("7").
  String _myAvatar() => VoiceAvatar.normalize(_readAvatar()).toString();

  Room? _room;
  EventsListener<RoomEvent>? _listener;

  /// Notified on entering a room (room) or leaving it (null) —
  /// watch-together binds the data channel to it.
  void Function(Room? room)? onRoomChanged;

  /// Current room — used by watch-together for the data channel.
  Room? get room => _room;

  String? get localIdentity => _room?.localParticipant?.identity;

  Future<void> createRoom({required String name, int capacity = 10}) =>
      _enter(() =>
          _api.create(name: name, capacity: capacity, avatar: _myAvatar()));

  Future<void> joinRoom(String code) =>
      _enter(() => _api.join(code, avatar: _myAvatar()));

  Future<void> _enter(Future<RoomCredentials> Function() fetch) async {
    if (state.isConnecting) return;
    state = state.copyWith(status: RoomStatus.connecting, error: null);
    try {
      final creds = await fetch();
      await _connect(creds);
    } on VoiceException catch (e) {
      state = state.copyWith(status: RoomStatus.idle, error: e.code);
    } catch (e) {
      debugPrint('VOICE connect err: $e');
      state = state.copyWith(
          status: RoomStatus.idle, error: VoiceErrorCode.joinFailed);
    }
  }

  Future<void> _connect(RoomCredentials creds) async {
    await _teardown();

    // Mic permission is required before connecting (we request it even though
    // we join muted).
    await Permission.microphone.request();

    final room = Room();
    _room = room;
    _listener = room.createListener();
    _bind(room);

    // URL comes from the response only.
    await room.connect(creds.url, creds.token);

    // Mic is always muted on join.
    await room.localParticipant?.setMicrophoneEnabled(false);

    state = state.copyWith(
      status: RoomStatus.connected,
      code: creds.code,
      name: creds.name,
      isAdmin: creds.admin,
      micOn: false,
      error: null,
    );
    _refreshMembers();
    onRoomChanged?.call(room); // → watch-together binds the data channel
  }

  void _bind(Room room) {
    _listener!
      ..on<ParticipantConnectedEvent>((_) => _refreshMembers())
      ..on<ParticipantDisconnectedEvent>((_) => _refreshMembers())
      ..on<TrackMutedEvent>((_) => _refreshMembers())
      ..on<TrackUnmutedEvent>((_) => _refreshMembers())
      ..on<TrackPublishedEvent>((_) => _refreshMembers())
      ..on<TrackUnpublishedEvent>((_) => _refreshMembers())
      ..on<ActiveSpeakersChangedEvent>((_) => _refreshMembers())
      // Avatar/badge arrive inside metadata with the participant state; redraw
      // if it's updated later so no stale image remains (Android updates on
      // every event).
      ..on<ParticipantMetadataUpdatedEvent>((_) => _refreshMembers())
      ..on<RoomDisconnectedEvent>((_) {
        // Includes the server kicking us or the room being ended.
        _teardown();
        state = const VoiceRoomState();
      });
  }

  void _refreshMembers() {
    final room = _room;
    if (room == null) return;

    // Each member's metadata says who they are: their avatar and whether
    // they're admin — this is how **everyone** sees the host badge and each
    // other's avatars. Empty/corrupt metadata ⇒ (0, false), member is kept.
    RoomMember toMember(Participant p, {required bool local}) {
      final meta = VoiceAvatar.parseMetadata(p.metadata);
      return RoomMember(
        identity: p.identity,
        name: p.name.isNotEmpty ? p.name : p.identity,
        speaking: p.isSpeaking,
        micOn: p.isMicrophoneEnabled(),
        isLocal: local,
        isAdmin: meta.isAdmin,
        avatar: meta.avatar,
      );
    }

    final members = <RoomMember>[
      if (room.localParticipant != null)
        toMember(room.localParticipant!, local: true),
      for (final p in room.remoteParticipants.values) toMember(p, local: false),
    ];
    state = state.copyWith(
      members: members,
      micOn: room.localParticipant?.isMicrophoneEnabled() ?? false,
    );
  }

  Future<void> toggleMic() async {
    final lp = _room?.localParticipant;
    if (lp == null) return;
    final next = !lp.isMicrophoneEnabled();
    if (next) {
      final granted = await Permission.microphone.request();
      if (!granted.isGranted) {
        state = state.copyWith(error: VoiceErrorCode.micDenied);
        return;
      }
    }
    await lp.setMicrophoneEnabled(next);
    _refreshMembers();
  }

  /// Permanent kick (admin) — via our server.
  Future<void> kick(String identity) async {
    if (!state.isAdmin || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      await _api.kick(code: state.code, identity: identity);
    } on VoiceException catch (e) {
      state = state.copyWith(error: e.code);
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  /// End the room for everyone (admin).
  Future<void> endRoom() async {
    if (!state.isAdmin || state.busy) return;
    state = state.copyWith(busy: true, error: null);
    try {
      await _api.end(state.code);
      await leave();
    } on VoiceException catch (e) {
      state = state.copyWith(busy: false, error: e.code);
    }
  }

  /// Leave (just me).
  Future<void> leave() async {
    await _teardown();
    state = const VoiceRoomState();
  }

  Future<void> _teardown() async {
    if (_room != null) onRoomChanged?.call(null); // detach the data channel first
    await _listener?.dispose();
    _listener = null;
    await _room?.disconnect();
    await _room?.dispose();
    _room = null;
  }

  @override
  void dispose() {
    _teardown();
    super.dispose();
  }
}
