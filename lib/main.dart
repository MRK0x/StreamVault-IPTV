import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:media_kit/media_kit.dart';

import 'ui/app.dart';

/// HTTPS interception via a proxy (Charles/Burp) — **for deliberate
/// inspection only**.
///
/// Off by default, so the app **always verifies certificates** and its requests
/// can't be intercepted easily — neither in release nor in development. It's
/// only enabled by a dev build passing `--dart-define=PROXY_DEBUG=true` (and
/// additionally guarded by `kDebugMode`), so it can never leak into a release
/// build.
const bool _debugSeeAll =
    kDebugMode && bool.fromEnvironment('PROXY_DEBUG', defaultValue: false);

/// App-wide network limits.
///
/// **Why?** Channel logos come from external hosts owned by the provider, not
/// us, and many are dead or slow (one returns 403, another never responds), and
/// a single host serves the logos of **3777 channels**. The image loader has no
/// default cap on connections per host, so hung connections pile up into the
/// hundreds (we measured 116 connections to a single address) until the app's
/// network is choked, and gateway requests sit in the queue and time out —
/// making the stream look like it's "loading forever".
///
/// The cap makes a dead host fail fast instead of swallowing the network.
class _AppHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context)
      // Plenty for the gateway, and stops a dead logo host from opening
      // dozens.
      ..maxConnectionsPerHost = 6
      ..connectionTimeout = const Duration(seconds: 8)
      // Don't keep idle connections for long (dead hosts leave them hanging).
      ..idleTimeout = const Duration(seconds: 8);
    if (_debugSeeAll) {
      // Dev only: accept any certificate, so whatever proxy you run shows
      // every request without setup. (The system proxy is read automatically
      // — we don't set it here.)
      client.badCertificateCallback = (cert, host, port) => true;
    }
    return client;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = _AppHttpOverrides();
  MediaKit.ensureInitialized(); // initialise libmpv
  // The app is portrait by default; only the player allows rotation while
  // watching.
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: MrkApp()));
}
