import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_state.dart';
import '../core/theme.dart';
import '../l10n/app_text.dart';
import '../state/locale_controller.dart';
import '../state/providers.dart';
import 'auth/login_screen.dart';
import 'shell/root_shell.dart';
import 'voice/voice_room_pill.dart';
import 'widgets/loading.dart';

/// Root Navigator key.
/// The floating pill lives in `builder` — i.e. **above** the Navigator — so
/// there is no Navigator in its context. We use this key to open the room
/// sheet from anywhere
/// (including over the fullscreen player).
final rootNavigatorKey = GlobalKey<NavigatorState>();

class MrkApp extends ConsumerWidget {
  const MrkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The app language is chosen by the user in Settings and persisted.
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'MRK0sLivE',
      navigatorKey: rootNavigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: LocaleController.supported,
      localizationsDelegates: const [
        AppText.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      // The floating room pill sits above all screens (Stack over Navigator).
      // Direction follows the language: Arabic RTL, English LTR.
      builder: (context, child) => Directionality(
        textDirection: locale.languageCode == 'en'
            ? TextDirection.ltr
            : TextDirection.rtl,
        child: Stack(
          children: [
            child ?? const SizedBox.shrink(),
            const VoiceRoomOverlay(),
          ],
        ),
      ),
      home: const _Gate(),
    );
  }
}

/// Routing gate based on the auth state.
class _Gate extends ConsumerStatefulWidget {
  const _Gate();

  @override
  ConsumerState<_Gate> createState() => _GateState();
}

class _GateState extends ConsumerState<_Gate> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(authControllerProvider.notifier).restore());
  }

  @override
  Widget build(BuildContext context) {
    // Session expired (refresh failed on 401) → log out + wipe account data,
    // otherwise the next account would see it (subscription/devices/catalog).
    ref.listen(sessionExpiredProvider, (_, _) {
      ref.read(authControllerProvider.notifier).onSessionExpired();
      clearAccountData(ref);
    });

    // **New session ⇒ fresh data.**
    // At logout the app screens stay alive during the transition animation
    // (350ms) while watching the account providers, so invalidating them
    // refetches without a token ⇒ a 401 that gets cached in the provider and
    // stays visible after the next login. So we drop it here on every login
    // so the new account's data is fetched clean.
    ref.listen(authControllerProvider.select((s) => s.status), (prev, next) {
      if (next == AuthStatus.authenticated &&
          prev != AuthStatus.authenticated) {
        clearAccountData(ref);
        // The catalog cache stays (loaded once) — cleared only if its owner
        // changes.
        syncCatalogOwner(ref, ref.read(authControllerProvider).username);
      }
    });

    final status = ref.watch(authControllerProvider).status;

    final Widget screen = switch (status) {
      AuthStatus.unknown => const Scaffold(body: LoadingView()),
      AuthStatus.authenticated => const RootShell(),
      _ => const LoginScreen(),
    };

    // Key on the **screen type**, not the raw state: `unauthenticated` and
    // `authenticating` show the same login screen, so distinguishing them
    // would rebuild it on every "Log in" tap and lose what the user typed
    // (making them retype after every failed attempt). Logging out
    // (authenticated → unauthenticated), however, changes the key so a
    // **fresh login screen with empty fields** appears — which is what we want.
    final screenKey = switch (status) {
      AuthStatus.unknown => 'loading',
      AuthStatus.authenticated => 'app',
      _ => 'login',
    };

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 350),
      child: KeyedSubtree(key: ValueKey(screenKey), child: screen),
    );
  }
}
