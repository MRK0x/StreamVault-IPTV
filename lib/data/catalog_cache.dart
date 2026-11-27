import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// On-disk catalog cache — loaded **once** and kept. It never expires
/// automatically: refresh is manual via "Sync all" (or pull-to-refresh).
///
/// We store the **raw JSON** as received from the server; decoding happens on a
/// background isolate (the provider catalog is ~35k items — decoding it on the
/// main thread freezes the UI).
class CatalogCache {
  CatalogCache._();

  static Directory? _dir;
  static const _stampFile = '_last_sync';

  static Future<Directory> _ensureDir() async {
    final cached = _dir;
    if (cached != null && await cached.exists()) return cached;
    final base = await getApplicationSupportDirectory();
    final d = Directory('${base.path}/catalog_cache');
    if (!await d.exists()) await d.create(recursive: true);
    return _dir = d;
  }

  static String _keyFor(String path) =>
      path.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  static Future<File> _fileFor(String path) async =>
      File('${(await _ensureDir()).path}/${_keyFor(path)}.json');

  /// Stored raw JSON for this path, or null if absent.
  static Future<String?> read(String path) async {
    try {
      final f = await _fileFor(path);
      if (!await f.exists()) return null;
      final s = await f.readAsString();
      return s.isEmpty ? null : s;
    } catch (e) {
      debugPrint('CACHE read err: $e');
      return null;
    }
  }

  static Future<void> write(String path, String raw) async {
    if (raw.isEmpty) return;
    try {
      final f = await _fileFor(path);
      await f.writeAsString(raw);
      await _stamp();
    } catch (e) {
      debugPrint('CACHE write err: $e');
    }
  }

  /// Clears the whole stored catalog ("Sync all" button).
  static Future<void> clear() async {
    try {
      final d = await _ensureDir();
      if (await d.exists()) await d.delete(recursive: true);
      _dir = null;
    } catch (e) {
      debugPrint('CACHE clear err: $e');
    }
  }

  static Future<void> _stamp() async {
    try {
      final f = File('${(await _ensureDir()).path}/$_stampFile');
      await f.writeAsString(DateTime.now().millisecondsSinceEpoch.toString());
    } catch (_) {}
  }

  /// Time of the last successful sync (shown in settings).
  static Future<DateTime?> lastSync() async {
    try {
      final f = File('${(await _ensureDir()).path}/$_stampFile');
      if (!await f.exists()) return null;
      final ms = int.tryParse(await f.readAsString());
      return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
    } catch (_) {
      return null;
    }
  }

  /// Is there a stored catalog at all?
  static Future<bool> get hasData async => (await lastSync()) != null;

  // ── Cache owner ───────────────────────────────────────────────────────
  //
  // The catalog comes from the server's `subscription.upstream`, which is
  // **optional**: subscriptions without a dedicated upstream all fall back to
  // `primary()` and so see the same catalog. So clearing it on every logout
  // makes no sense (it contradicts "loaded once"). But it **may** differ if the
  // admin assigns a dedicated host to a subscription — so we clear it only when
  // the **account owner** actually changes.

  static const _ownerFile = '_owner';

  /// Username the stored catalog was fetched for.
  static Future<String?> owner() async {
    try {
      final f = File('${(await _ensureDir()).path}/$_ownerFile');
      if (!await f.exists()) return null;
      final s = (await f.readAsString()).trim();
      return s.isEmpty ? null : s;
    } catch (_) {
      return null;
    }
  }

  static Future<void> setOwner(String username) async {
    try {
      final f = File('${(await _ensureDir()).path}/$_ownerFile');
      await f.writeAsString(username);
    } catch (_) {}
  }
}
