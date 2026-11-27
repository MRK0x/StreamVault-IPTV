import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/voice/voice_avatar.dart';

/// Locks down the **wire contract** shared with Android. Any failure here
/// means an iPhone member's avatar renders wrong for Android members.
/// Reference behaviour: `VoiceAvatar.parseMetadata` in the Android source
/// (org.json is lenient, so we deliberately mimic its leniency).
void main() {
  group('parseMetadata — valid input', () {
    test('av as string + adm=true', () {
      final r = VoiceAvatar.parseMetadata('{"v":1,"av":"7","adm":true}');
      expect(r.avatar, 7);
      expect(r.isAdmin, isTrue);
    });

    test('adm=false', () {
      final r = VoiceAvatar.parseMetadata('{"v":1,"av":"20","adm":false}');
      expect(r.avatar, 20);
      expect(r.isAdmin, isFalse);
    });

    test('av=0 lower bound', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"0"}').avatar, 0);
    });
  });

  group('parseMetadata — org.json leniency (must match it)', () {
    test('av as number, not string → accepted', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":7}').avatar, 7);
    });

    test('av with whitespace → trimmed', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":" 7 "}').avatar, 7);
    });

    test('av with leading zero → accepted on receive', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"07"}').avatar, 7);
    });

    test('v as string "1" → accepted (optInt coerces strings)', () {
      expect(VoiceAvatar.parseMetadata('{"v":"1","av":"3"}').avatar, 3);
    });

    test('adm as string "true" → accepted', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"1","adm":"true"}').isAdmin,
          isTrue);
    });
  });

  group('parseMetadata — defaults on bad input (never throws or drops the member)', () {
    test('v other than 1 drops the avatar **and the badge together**', () {
      final r = VoiceAvatar.parseMetadata('{"v":2,"av":"7","adm":true}');
      expect(r.avatar, 0);
      expect(r.isAdmin, isFalse);
    });

    test('missing v → default', () {
      final r = VoiceAvatar.parseMetadata('{"av":"7","adm":true}');
      expect(r.avatar, 0);
      expect(r.isAdmin, isFalse);
    });

    test('av out of range (21) → 0', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"21"}').avatar, 0);
    });

    test('negative av → 0', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"-1"}').avatar, 0);
    });

    test('missing av → 0', () {
      expect(VoiceAvatar.parseMetadata('{"v":1}').avatar, 0);
    });

    test('non-numeric av → 0', () {
      expect(VoiceAvatar.parseMetadata('{"v":1,"av":"abc"}').avatar, 0);
    });

    test('null / empty / whitespace → default', () {
      for (final raw in [null, '', '   ']) {
        final r = VoiceAvatar.parseMetadata(raw);
        expect(r.avatar, 0);
        expect(r.isAdmin, isFalse);
      }
    });

    test('malformed JSON → default, no throw', () {
      for (final raw in ['not json', '{', '[1,2]', '"str"']) {
        final r = VoiceAvatar.parseMetadata(raw);
        expect(r.avatar, 0, reason: raw);
        expect(r.isAdmin, isFalse, reason: raw);
      }
    });
  });

  group('assetOf — index → file name', () {
    test('7 → avatar_07 (zero-padded in the name only)', () {
      expect(VoiceAvatar.assetOf(7), 'assets/avatars/avatar_07.webp');
    });

    test('bounds 0 and 20', () {
      expect(VoiceAvatar.assetOf(0), 'assets/avatars/avatar_00.webp');
      expect(VoiceAvatar.assetOf(20), 'assets/avatars/avatar_20.webp');
    });

    test('out of range → falls back to avatar_00 instead of crashing', () {
      expect(VoiceAvatar.assetOf(21), 'assets/avatars/avatar_00.webp');
      expect(VoiceAvatar.assetOf(-1), 'assets/avatars/avatar_00.webp');
    });
  });

  test('all 21 assets actually exist on disk', () {
    for (var i = 0; i < VoiceAvatar.count; i++) {
      expect(File(VoiceAvatar.assetOf(i)).existsSync(), isTrue,
          reason: 'missing: ${VoiceAvatar.assetOf(i)}');
    }
  });
}
