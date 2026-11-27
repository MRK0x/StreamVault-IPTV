import 'dart:ui' show Locale;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../auth/auth_api.dart';
import '../auth/auth_controller.dart';
import '../auth/auth_state.dart';
import '../core/config.dart';
import '../data/account_api.dart';
import '../data/api_catalog_repository.dart';
import '../data/catalog_cache.dart';
import '../data/catalog_repository.dart';
import '../data/models/account.dart';
import '../data/models/category_group.dart';
import '../data/models/media_item.dart';
import '../data/models/series_info.dart';
import '../network/dio_client.dart';
import '../network/session_store.dart';
import '../voice/content_resolver.dart';
import '../voice/voice_api.dart';
import '../voice/voice_room_manager.dart';
import '../voice/voice_room_state.dart';
import '../voice/watch_party_manager.dart';
import 'locale_controller.dart';
import 'voice_avatar_controller.dart';

/// Dependency-injection (DI) container.

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );
});

final sessionStoreProvider = Provider<SessionStore>((ref) {
  return SessionStore(ref.watch(secureStorageProvider));
});

/// App language (Arabic/English) — persisted, applied instantly to all screens.
final localeProvider = StateNotifierProvider<LocaleController, Locale>((ref) {
  return LocaleController(ref.watch(secureStorageProvider));
});

/// Session-expired signal — bumped by the auth interceptor when refresh fails;
/// the UI listens to it to log out (breaks the dio↔authController cycle).
final sessionExpiredProvider = StateProvider<int>((ref) => 0);

/// dio client — HMAC + Bearer/refresh.
final dioProvider = Provider<Dio>((ref) {
  return DioClient.create(
    session: ref.watch(sessionStoreProvider),
    onSessionExpired: () => ref.read(sessionExpiredProvider.notifier).state++,
  );
});

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    session: ref.watch(sessionStoreProvider),
    api: ref.watch(authApiProvider),
  );
});

/// The catalog: real when secrets are available, otherwise demo.
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
  if (AppConfig.useMockData) {
    return const MockCatalogRepository();
  }
  return ApiCatalogRepository(ref.watch(dioProvider));
});

// Catalog providers for the tab screens.
final liveChannelsProvider = FutureProvider<List<MediaItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).liveChannels();
});

final moviesProvider = FutureProvider<List<MediaItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).movies();
});

final seriesProvider = FutureProvider<List<MediaItem>>((ref) {
  return ref.watch(catalogRepositoryProvider).series();
});

// Groups organised by category for the browse screens.
final liveGroupsProvider = FutureProvider<List<CategoryGroup>>((ref) {
  return ref.watch(catalogRepositoryProvider).liveGroups();
});

final movieGroupsProvider = FutureProvider<List<CategoryGroup>>((ref) {
  return ref.watch(catalogRepositoryProvider).movieGroups();
});

final seriesGroupsProvider = FutureProvider<List<CategoryGroup>>((ref) {
  return ref.watch(catalogRepositoryProvider).seriesGroups();
});

/// Series details (seasons + episodes) by series_id — fetched on demand.
final seriesInfoProvider =
    FutureProvider.family<SeriesInfo, String>((ref, seriesId) {
  return ref.watch(catalogRepositoryProvider).seriesInfo(seriesId);
});

// ── Voice rooms + watch party ──────────────────────────────────────────

/// Voice service on the **shared dio**: HMAC signing and the Bearer token are
/// added automatically because the voice host is one of our domains.
final voiceApiProvider = Provider<VoiceApi>((ref) {
  return VoiceApi(ref.watch(dioProvider));
});

/// Locally chosen avatar (0..20) — persisted and sent on the next join.
final voiceAvatarProvider =
    StateNotifierProvider<VoiceAvatarController, int>((ref) {
  return VoiceAvatarController(ref.watch(secureStorageProvider));
});

final voiceRoomProvider =
    StateNotifierProvider<VoiceRoomManager, VoiceRoomState>((ref) {
  final m = VoiceRoomManager(
    ref.watch(voiceApiProvider),
    // Read at join time (the server bakes it into the token, so it stays
    // fixed for the whole session).
    readAvatar: () => ref.read(voiceAvatarProvider),
  );
  // Attach/detach the watch-party data channel as the room is joined/left.
  m.onRoomChanged = (room) {
    final wp = ref.read(watchPartyProvider);
    if (room == null) {
      wp.detach();
    } else {
      wp.attach(room);
    }
  };
  return m;
});

/// Watch-party manager — stays alive for the whole session (LiveKit data
/// channel).
final watchPartyProvider = ChangeNotifierProvider<WatchPartyManager>((ref) {
  final m = WatchPartyManager();
  ref.onDispose(m.dispose);
  return m;
});

/// Resolves a watch-party message to a playable item on this device.
final contentResolverProvider = Provider<ContentResolver>((ref) {
  return ContentResolver(ref.watch(catalogRepositoryProvider));
});


// ── Account and devices ────────────────────────────────────────────────

final accountApiProvider = Provider<AccountApi>((ref) {
  return AccountApi(ref.watch(dioProvider));
});

/// Account profile (subscription: plan/expiry/device limit) — `GET /api/me/`.
final accountProvider = FutureProvider<Account>((ref) {
  return ref.watch(accountApiProvider).me();
});

/// The user's active devices — `GET /api/devices/`.
final devicesProvider = FutureProvider<List<UserDevice>>((ref) {
  return ref.watch(accountApiProvider).devices();
});

/// Time of the last catalog sync (shown in Settings).
final lastSyncProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(catalogRepositoryProvider).lastSync();
});

/// Everything tied to **a specific account** — dropped from memory when the
/// session changes, otherwise the previous account's data would leak (its
/// subscription, devices and content).
///
/// Note: this is **in-memory invalidation only**; the on-disk catalog cache
/// stays (see [syncCatalogOwner]).
final _accountScopedProviders = <ProviderOrFamily>[
  accountProvider, // /api/me/ — subscription and plan
  devicesProvider, // account devices
  lastSyncProvider,
  liveChannelsProvider,
  moviesProvider,
  seriesProvider,
  liveGroupsProvider,
  movieGroupsProvider,
  seriesGroupsProvider,
  seriesInfoProvider,
];

/// **Full** logout: clears the session, leaves the voice room, and drops the
/// account's data from memory.
///
/// ❌ **Does not clear the catalog cache**: the requirement is to load it once
/// and keep it, with manual refresh via "Sync all". The catalog isn't
/// session-specific anyway — it comes from `subscription.upstream`, which is
/// optional on the server, so every account without its own upstream host
/// sees the same catalog. It's only cleared if its owner changes
/// ([syncCatalogOwner]).
Future<void> logoutAndClear(WidgetRef ref) async {
  // Leave any voice room first (a live LiveKit connection with the old
  // account's token).
  await ref.read(voiceRoomProvider.notifier).leave();
  await ref.read(authControllerProvider.notifier).logout();
  for (final p in _accountScopedProviders) {
    ref.invalidate(p);
  }
}

/// Clears the catalog cache **only if the account owner changed**.
///
/// Logout and login with the same account ⇒ the cache is valid and stays (no
/// needless ~17MB download).
/// A different account ⇒ may have a different `upstream`, hence different
/// content ⇒ we clear it.
Future<void> syncCatalogOwner(WidgetRef ref, String? username) async {
  if (username == null || username.isEmpty) return;
  final previous = await CatalogCache.owner();
  if (previous != null && previous != username) {
    await ref.read(catalogRepositoryProvider).purgeStorage();
    for (final p in _accountScopedProviders) {
      ref.invalidate(p);
    }
  }
  await CatalogCache.setOwner(username);
}

/// Wipes the account's data from memory/disk without touching the session —
/// for session expiry (401 after a failed refresh), where the tokens are
/// cleared elsewhere.
void clearAccountData(WidgetRef ref) {
  for (final p in _accountScopedProviders) {
    ref.invalidate(p);
  }
}

/// "Sync all": clears disk + memory, then reloads the full catalog.
Future<void> syncAllCatalog(WidgetRef ref) async {
  await ref.read(catalogRepositoryProvider).purgeStorage();
  for (final p in [
    liveChannelsProvider,
    moviesProvider,
    seriesProvider,
    liveGroupsProvider,
    movieGroupsProvider,
    seriesGroupsProvider,
  ]) {
    ref.invalidate(p);
  }
  // Wait for the full reload before reporting completion.
  await Future.wait([
    ref.read(liveChannelsProvider.future),
    ref.read(moviesProvider.future),
    ref.read(seriesProvider.future),
  ]);
  ref.invalidate(lastSyncProvider);
}
