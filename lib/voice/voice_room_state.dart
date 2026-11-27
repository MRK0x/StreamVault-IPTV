import 'voice_api.dart' show VoiceErrorCode;

/// A member of the voice room.
class RoomMember {
  const RoomMember({
    required this.identity,
    required this.name,
    required this.speaking,
    required this.micOn,
    required this.isLocal,
    required this.isAdmin,
    required this.avatar,
  });

  /// LiveKit identity — sent in the kick request.
  final String identity;
  final String name;
  final bool speaking;
  final bool micOn;
  final bool isLocal;

  /// Admin? — **from this member's own metadata** (not from "am I admin").
  /// This way **all** members see the host badge, not just the host.
  final bool isAdmin;

  /// Avatar image index 0..20 — from the member's metadata.
  final int avatar;
}

enum RoomStatus { idle, connecting, connected }

class VoiceRoomState {
  const VoiceRoomState({
    this.status = RoomStatus.idle,
    this.code = '',
    this.name = '',
    this.isAdmin = false,
    this.micOn = false,
    this.members = const [],
    this.error,
    this.busy = false,
  });

  // (error is now VoiceErrorCode? — localized in the UI)

  final RoomStatus status;
  final String code;
  final String name;
  final bool isAdmin;
  final bool micOn;
  final List<RoomMember> members;
  final VoiceErrorCode? error;

  /// Operation in progress (kick/end) — to disable the buttons.
  final bool busy;

  bool get inRoom => status == RoomStatus.connected;
  bool get isConnecting => status == RoomStatus.connecting;

  VoiceRoomState copyWith({
    RoomStatus? status,
    String? code,
    String? name,
    bool? isAdmin,
    bool? micOn,
    List<RoomMember>? members,
    VoiceErrorCode? error,
    bool? busy,
  }) =>
      VoiceRoomState(
        status: status ?? this.status,
        code: code ?? this.code,
        name: name ?? this.name,
        isAdmin: isAdmin ?? this.isAdmin,
        micOn: micOn ?? this.micOn,
        members: members ?? this.members,
        error: error,
        busy: busy ?? this.busy,
      );
}
