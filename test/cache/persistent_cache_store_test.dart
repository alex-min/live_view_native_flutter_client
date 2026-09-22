import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/cache/persistent_live_view_cache_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const namespace = LiveCacheNamespace(
    origin: 'https://finance.example',
    scope: LiveCacheScope.user,
    identity: 'opaque-user-a',
    manifestVersion: 'finance-v1',
    rendererVersion: 'renderer-v1',
    locale: 'en',
    theme: 'cosmic-light',
  );
  const otherNamespace = LiveCacheNamespace(
    origin: 'https://finance.example',
    scope: LiveCacheScope.user,
    identity: 'opaque-user-b',
    manifestVersion: 'finance-v1',
    rendererVersion: 'renderer-v1',
    locale: 'en',
    theme: 'cosmic-light',
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({'unrelated': 'keep me'});
  });

  Future<PersistentLiveViewCacheStore> store({
    int maximumSnapshotBytes = 512 * 1024,
    int maximumNamespaceBytes = 4 * 1024 * 1024,
  }) async => PersistentLiveViewCacheStore(
    preferences: await SharedPreferences.getInstance(),
    maximumSnapshotBytes: maximumSnapshotBytes,
    maximumNamespaceBytes: maximumNamespaceBytes,
  );

  LiveCacheSnapshot snapshot(
    String route,
    String content, {
    LiveCacheNamespace cacheNamespace = namespace,
  }) => LiveCacheSnapshot(
    namespace: cacheNamespace,
    route: Uri.parse(route),
    storedAt: DateTime.utc(2026, 9, 22),
    rendered: {
      's': ['<Text>$content</Text>'],
    },
  );

  test('manifests and snapshots survive store recreation', () async {
    var firstStore = await store();
    var manifest = StoredLiveCacheManifest(
      manifest: LiveCacheManifest(
        version: 'finance-v1',
        scope: LiveCacheScope.user,
        identity: 'opaque-user-a',
        strategy: LiveCacheStrategy.staleWhileRevalidate,
        routes: [
          LiveCacheRoute(
            href: Uri(path: '/accounts'),
            maxAge: Duration(minutes: 5),
            priority: LiveCachePriority.high,
          ),
        ],
      ),
      storedAt: DateTime.utc(2026, 9, 22),
    );
    var accounts = snapshot('/accounts', 'Accounts');
    await firstStore.writeManifest('finance.example|en', manifest);
    expect(await firstStore.writeSnapshot(accounts), isTrue);

    var recreated = await store();
    var restoredManifest = await recreated.readManifest('finance.example|en');
    var restoredSnapshot = await recreated.readSnapshot(
      namespace,
      Uri.parse('/accounts'),
    );

    expect(restoredManifest?.manifest.version, 'finance-v1');
    expect(restoredManifest?.manifest.routes.single.href.path, '/accounts');
    expect(restoredManifest?.storedAt, DateTime.utc(2026, 9, 22));
    expect(restoredSnapshot?.rendered, accounts.rendered);
    expect(restoredSnapshot?.storedAt, accounts.storedAt);
  });

  test(
    'corrupt and incompatible envelopes become misses and are removed',
    () async {
      var cache = await store();
      await cache.writeSnapshot(snapshot('/accounts', 'Accounts'));
      var preferences = await SharedPreferences.getInstance();
      var snapshotKey = preferences.getKeys().singleWhere(
        (key) => key.contains('namespace.'),
      );

      await preferences.setString(snapshotKey, '{broken');
      expect(
        await cache.readSnapshot(namespace, Uri.parse('/accounts')),
        isNull,
      );
      expect(preferences.containsKey(snapshotKey), isFalse);

      await cache.writeSnapshot(snapshot('/accounts', 'Accounts'));
      snapshotKey = preferences.getKeys().singleWhere(
        (key) => key.contains('namespace.'),
      );
      var envelope = jsonDecode(preferences.getString(snapshotKey)!) as Map;
      envelope['version'] = 999;
      await preferences.setString(snapshotKey, jsonEncode(envelope));

      expect(
        await cache.readSnapshot(namespace, Uri.parse('/accounts')),
        isNull,
      );
      expect(preferences.containsKey(snapshotKey), isFalse);
    },
  );

  test(
    'oversized snapshots are rejected without replacing a valid entry',
    () async {
      var cache = await store(
        maximumSnapshotBytes: 60,
        maximumNamespaceBytes: 120,
      );
      var valid = snapshot('/accounts', 'Accounts');
      var oversized = snapshot('/accounts', 'x' * 200);
      expect(await cache.writeSnapshot(valid), isTrue);

      expect(await cache.writeSnapshot(oversized), isFalse);
      expect(
        (await cache.readSnapshot(namespace, valid.route))?.rendered,
        valid.rendered,
      );

      var stricterStore = await store(
        maximumSnapshotBytes: 10,
        maximumNamespaceBytes: 20,
      );
      expect(await stricterStore.readSnapshot(namespace, valid.route), isNull);
    },
  );

  test('unsafe snapshot routes are never persisted', () async {
    var cache = await store();
    var unsafe = LiveCacheSnapshot(
      namespace: namespace,
      route: Uri.parse('https://other.example/accounts'),
      storedAt: DateTime.utc(2026, 9, 22),
      rendered: const {
        's': ['unsafe'],
      },
    );

    expect(await cache.writeSnapshot(unsafe), isFalse);
    expect(
      (await SharedPreferences.getInstance()).getKeys().where(
        (key) => key.contains('namespace.'),
      ),
      isEmpty,
    );
  });

  test('bootstrap secrets are never persisted', () async {
    var cache = await store();
    var sensitive = LiveCacheSnapshot(
      namespace: namespace,
      route: Uri.parse('/accounts'),
      storedAt: DateTime.utc(2026, 9, 22),
      rendered: {
        's': ['<input name="_csrf_token" value="secret">'],
      },
    );

    expect(await cache.writeSnapshot(sensitive), isFalse);
    expect(
      (await SharedPreferences.getInstance()).getKeys().where(
        (key) => key.contains('namespace.'),
      ),
      isEmpty,
    );
  });

  test(
    'namespace clearing does not affect another user or app preferences',
    () async {
      var cache = await store();
      var first = snapshot('/accounts', 'First user');
      var second = snapshot(
        '/accounts',
        'Second user',
        cacheNamespace: otherNamespace,
      );
      await cache.writeSnapshot(first);
      await cache.writeSnapshot(second);

      await cache.clearNamespace(namespace);

      expect(await cache.readSnapshot(namespace, first.route), isNull);
      expect(
        (await cache.readSnapshot(otherNamespace, second.route))?.rendered,
        second.rendered,
      );
      expect(
        (await SharedPreferences.getInstance()).getString('unrelated'),
        'keep me',
      );
    },
  );

  test(
    'retains declared routes and evicts least recently used snapshots',
    () async {
      var first = snapshot('/first', 'first');
      var second = snapshot('/second', 'second');
      var third = snapshot('/third', 'third');
      var totalSize = [first, second, third]
          .map((value) => utf8.encode(jsonEncode(value.rendered)).length)
          .reduce((left, right) => left + right);
      var cache = await store(
        maximumSnapshotBytes: 1000,
        maximumNamespaceBytes: totalSize - 1,
      );
      await cache.writeSnapshot(first);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cache.writeSnapshot(second);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cache.readSnapshot(namespace, first.route);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await cache.writeSnapshot(third);

      expect(await cache.readSnapshot(namespace, first.route), isNotNull);
      expect(await cache.readSnapshot(namespace, second.route), isNull);
      expect(await cache.readSnapshot(namespace, third.route), isNotNull);

      await cache.retainRoutes(namespace, {third.route});
      expect(await cache.readSnapshot(namespace, first.route), isNull);
      expect(await cache.readSnapshot(namespace, third.route), isNotNull);
    },
  );

  test('clear removes only LiveView cache records', () async {
    var cache = await store();
    await cache.writeManifest(
      'manifest',
      StoredLiveCacheManifest(
        manifest: const LiveCacheManifest(
          version: '1',
          scope: LiveCacheScope.public,
          identity: null,
          strategy: LiveCacheStrategy.staleWhileRevalidate,
          routes: [],
        ),
        storedAt: DateTime.utc(2026, 9, 22),
      ),
    );
    await cache.writeSnapshot(snapshot('/accounts', 'Accounts'));

    await cache.clear();

    var preferences = await SharedPreferences.getInstance();
    expect(
      preferences.getKeys().where(
        (key) => key.startsWith(PersistentLiveViewCacheStore.storagePrefix),
      ),
      isEmpty,
    );
    expect(preferences.getString('unrelated'), 'keep me');
  });
}
