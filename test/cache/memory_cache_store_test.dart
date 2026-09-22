import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/cache/memory_live_view_cache_store.dart';

void main() {
  const namespace = LiveCacheNamespace(
    origin: 'https://finance.example',
    scope: LiveCacheScope.user,
    identity: 'user-a',
    manifestVersion: 'manifest-v1',
    rendererVersion: 'renderer-v1',
    locale: 'en',
    theme: 'cosmic-light',
  );
  const otherNamespace = LiveCacheNamespace(
    origin: 'https://finance.example',
    scope: LiveCacheScope.user,
    identity: 'user-b',
    manifestVersion: 'manifest-v1',
    rendererVersion: 'renderer-v1',
    locale: 'en',
    theme: 'cosmic-light',
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

  test('stores manifests independently from route snapshots', () async {
    var store = MemoryLiveViewCacheStore();
    var storedManifest = StoredLiveCacheManifest(
      manifest: const LiveCacheManifest(
        version: 'manifest-v1',
        scope: LiveCacheScope.user,
        identity: 'user-a',
        strategy: LiveCacheStrategy.staleWhileRevalidate,
        routes: [],
      ),
      storedAt: DateTime.utc(2026, 9, 22),
    );

    await store.writeManifest('finance|en|cosmic-light', storedManifest);

    expect(
      await store.readManifest('finance|en|cosmic-light'),
      same(storedManifest),
    );
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
  });

  test('reads, removes, and clears snapshots within one namespace', () async {
    var store = MemoryLiveViewCacheStore();
    var accounts = snapshot('/accounts', 'Accounts');
    var settings = snapshot('/settings', 'Settings');

    expect(await store.writeSnapshot(accounts), isTrue);
    expect(await store.writeSnapshot(settings), isTrue);
    expect(
      (await store.readSnapshot(namespace, Uri.parse('/accounts')))?.rendered,
      accounts.rendered,
    );

    await store.removeSnapshot(namespace, Uri.parse('/accounts'));
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
    expect(
      (await store.readSnapshot(namespace, Uri.parse('/settings')))?.rendered,
      settings.rendered,
    );

    await store.clearNamespace(namespace);
    expect(await store.readSnapshot(namespace, Uri.parse('/settings')), isNull);
  });

  test('retains only routes still declared by the manifest', () async {
    var store = MemoryLiveViewCacheStore();
    await store.writeSnapshot(snapshot('/accounts', 'Accounts'));
    await store.writeSnapshot(snapshot('/settings', 'Settings'));

    await store.retainRoutes(namespace, {Uri.parse('/accounts')});

    expect(
      await store.readSnapshot(namespace, Uri.parse('/accounts')),
      isNotNull,
    );
    expect(await store.readSnapshot(namespace, Uri.parse('/settings')), isNull);
  });

  test('detaches nested render data before storing it', () async {
    var store = MemoryLiveViewCacheStore();
    var dynamicText = <dynamic>['Before'];
    var original = LiveCacheSnapshot(
      namespace: namespace,
      route: Uri.parse('/accounts'),
      storedAt: DateTime.utc(2026, 9, 22),
      rendered: {
        's': ['<Text>', '</Text>'],
        '0': dynamicText,
      },
    );
    await store.writeSnapshot(original);

    dynamicText[0] = 'After';

    var restored = await store.readSnapshot(namespace, original.route);
    expect(restored?.rendered['0'], ['Before']);
  });

  test('keeps user namespaces isolated', () async {
    var store = MemoryLiveViewCacheStore();
    var first = snapshot('/accounts', 'First user');
    var second = snapshot(
      '/accounts',
      'Second user',
      cacheNamespace: otherNamespace,
    );

    await store.writeSnapshot(first);
    await store.writeSnapshot(second);
    await store.clearNamespace(namespace);

    expect(await store.readSnapshot(namespace, first.route), isNull);
    expect(
      (await store.readSnapshot(otherNamespace, second.route))?.rendered,
      second.rendered,
    );
  });

  test('rejects oversized and non-serializable snapshots', () async {
    var store = MemoryLiveViewCacheStore(
      maximumSnapshotBytes: 40,
      maximumNamespaceBytes: 100,
    );
    var oversized = snapshot('/accounts', 'x' * 100);
    var unsupported = LiveCacheSnapshot(
      namespace: namespace,
      route: Uri.parse('/settings'),
      storedAt: DateTime.utc(2026, 9, 22),
      rendered: {'unsupported': Object()},
    );

    expect(await store.writeSnapshot(oversized), isFalse);
    expect(await store.writeSnapshot(unsupported), isFalse);
    expect(await store.readSnapshot(namespace, oversized.route), isNull);
    expect(await store.readSnapshot(namespace, unsupported.route), isNull);

    var sensitive = LiveCacheSnapshot(
      namespace: namespace,
      route: Uri.parse('/transactions'),
      storedAt: DateTime.utc(2026, 9, 22),
      rendered: {
        's': ['<div data-phx-session="signed">'],
      },
    );
    expect(await store.writeSnapshot(sensitive), isFalse);
  });

  test('evicts the least recently used snapshot to stay bounded', () async {
    var first = snapshot('/first', 'first');
    var second = snapshot('/second', 'second');
    var third = snapshot('/third', 'third');
    var firstSize = _renderedSize(first);
    var secondSize = _renderedSize(second);
    var thirdSize = _renderedSize(third);
    var store = MemoryLiveViewCacheStore(
      maximumSnapshotBytes: 1000,
      maximumNamespaceBytes: firstSize + secondSize + thirdSize - 1,
    );

    await store.writeSnapshot(first);
    await store.writeSnapshot(second);
    // Reading first makes second the least recently used entry.
    await store.readSnapshot(namespace, first.route);
    await store.writeSnapshot(third);

    expect(
      (await store.readSnapshot(namespace, first.route))?.rendered,
      first.rendered,
    );
    expect(await store.readSnapshot(namespace, second.route), isNull);
    expect(
      (await store.readSnapshot(namespace, third.route))?.rendered,
      third.rendered,
    );
  });

  test('clear removes both manifests and every namespace', () async {
    var store = MemoryLiveViewCacheStore();
    var manifest = StoredLiveCacheManifest(
      manifest: const LiveCacheManifest(
        version: '1',
        scope: LiveCacheScope.public,
        identity: null,
        strategy: LiveCacheStrategy.staleWhileRevalidate,
        routes: [],
      ),
      storedAt: DateTime.utc(2026, 9, 22),
    );
    await store.writeManifest('manifest', manifest);
    await store.writeSnapshot(snapshot('/accounts', 'First user'));
    await store.writeSnapshot(
      snapshot('/accounts', 'Second user', cacheNamespace: otherNamespace),
    );

    await store.clear();

    expect(await store.readManifest('manifest'), isNull);
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
    expect(
      await store.readSnapshot(otherNamespace, Uri.parse('/accounts')),
      isNull,
    );
  });
}

int _renderedSize(LiveCacheSnapshot snapshot) {
  return utf8.encode(jsonEncode(snapshot.rendered)).length;
}
