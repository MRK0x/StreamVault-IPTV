import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../voice/voice_avatar.dart';

/// Local avatar choice — persisted and sent on the **next join**.
///
/// The server stamps the avatar into the session token, so changing it while
/// you're in a room doesn't affect your current room — it applies to the next
/// one (same as Android).
///
/// Storage: key `voice_avatar`, value stored **as a string** — matches the
/// DataStore on Android.
class VoiceAvatarController extends StateNotifier<int> {
  VoiceAvatarController(this._storage) : super(VoiceAvatar.defaultIndex) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  static const _key = 'voice_avatar';

  Future<void> _restore() async {
    // Missing/corrupt value → the default (0).
    state = VoiceAvatar.normalizeRaw(await _storage.read(key: _key));
  }

  Future<void> select(int index) async {
    final i = VoiceAvatar.normalize(index);
    if (i == state) return;
    state = i;
    await _storage.write(key: _key, value: i.toString());
  }
}
