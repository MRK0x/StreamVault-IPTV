import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mrk0slive/data/catalog_cache.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

/// Locks in the rule: **the catalog is loaded once and kept** — not cleared on
/// logout, only when the account owner changes (it comes from
/// `subscription.upstream`, which is optional on the server: without a
/// dedicated host ⇒ all accounts see the same catalog).
class _FakePathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _FakePathProvider(this.root);
  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}

void main() {
  late Directory tmp;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('catalog_owner_test');
    PathProviderPlatform.instance = _FakePathProvider(tmp.path);
    await CatalogCache.clear(); // start clean (state is static across tests)
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  test('no owner initially', () async {
    expect(await CatalogCache.owner(), isNull);
  });

  test('owner is saved and read back', () async {
    await CatalogCache.setOwner('zooozy');
    expect(await CatalogCache.owner(), 'zooozy');
  });

  test('switching the owner updates the value', () async {
    await CatalogCache.setOwner('zooozy');
    await CatalogCache.setOwner('ahmed');
    expect(await CatalogCache.owner(), 'ahmed');
  });

  test('catalog and owner survive "logout" (no clearing)', () async {
    await CatalogCache.write('/api/tv/live/streams', '[{"id":1}]');
    await CatalogCache.setOwner('zooozy');

    // Logout and login with the same account: clear nothing.
    expect(await CatalogCache.owner(), 'zooozy');
    expect(await CatalogCache.read('/api/tv/live/streams'), '[{"id":1}]');
  });

  test('clear wipes the catalog (on account switch or "Sync all")', () async {
    await CatalogCache.write('/api/tv/live/streams', '[{"id":1}]');
    await CatalogCache.clear();
    expect(await CatalogCache.read('/api/tv/live/streams'), isNull);
  });
}
