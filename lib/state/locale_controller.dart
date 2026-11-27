import 'dart:ui';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app language — Arabic/English only, persisted and restored across
/// launches.
///
/// Default on first launch: the system language if supported, otherwise
/// Arabic.
class LocaleController extends StateNotifier<Locale> {
  LocaleController(this._storage) : super(_systemDefault()) {
    _restore();
  }

  final FlutterSecureStorage _storage;

  static const _key = 'app_locale';

  static const supported = <Locale>[Locale('ar'), Locale('en')];

  static Locale _systemDefault() {
    final code = PlatformDispatcher.instance.locale.languageCode;
    return code == 'en' ? const Locale('en') : const Locale('ar');
  }

  Future<void> _restore() async {
    final saved = await _storage.read(key: _key);
    if (saved == 'ar' || saved == 'en') state = Locale(saved!);
  }

  Future<void> set(Locale locale) async {
    if (locale.languageCode == state.languageCode) return;
    state = locale;
    await _storage.write(key: _key, value: locale.languageCode);
  }
}

/// The language's name in its own language (not translated — this is how
/// iOS/Android display it).
String localeName(Locale l) => l.languageCode == 'en' ? 'English' : 'العربية';
