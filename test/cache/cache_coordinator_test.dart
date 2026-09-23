import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_coordinator.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/cache/memory_live_view_cache_store.dart';

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
  final manifest = LiveCacheManifest(
    version: 'finance-v1',
    scope: LiveCacheScope.user,
    identity: 'opaque-user-a',
    strategy: LiveCacheStrategy.staleWhileRevalidate,
    routes: [
      LiveCacheRoute(
        href: Uri.parse('/accounts'),
        maxAge: const Duration(minutes: 5),
        priority: LiveCachePriority.normal,
      ),
      LiveCacheRoute(
        href: Uri.parse('/transactions'),
        maxAge: const Duration(minutes: 5),
        priority: LiveCachePriority.normal,
      ),
    ],
  );
  final storedAt = DateTime.utc(2026, 9, 22, 12);

  test(
    'accepts a matching manifest, persists it, and prunes old routes',
    () async {
      var store = MemoryLiveViewCacheStore();
      await store.writeSnapshot(
        LiveCacheSnapshot(
          namespace: namespace,
          route: Uri.parse('/removed'),
          storedAt: storedAt,
          rendered: const {
            's': ['removed'],
          },
        ),
      );
      var coordinator = LiveViewCacheCoordinator(
        store: store,
        now: () => storedAt,
      );

      expect(
        await coordinator.acceptManifest(
          namespace: namespace,
          manifest: manifest,
        ),
        isTrue,
      );

      expect(coordinator.namespace, namespace);
      expect(coordinator.manifest, manifest);
      expect(
        await store.readManifest(
          LiveViewCacheCoordinator.manifestStorageKey(namespace),
        ),
        isNotNull,
      );
      expect(
        await store.readSnapshot(namespace, Uri.parse('/removed')),
        isNull,
      );
    },
  );

  test('rejects mismatched namespaces and unsafe manifest routes', () async {
    var coordinator = LiveViewCacheCoordinator(
      store: MemoryLiveViewCacheStore(),
    );
    var wrongIdentity = LiveCacheNamespace(
      origin: namespace.origin,
      scope: namespace.scope,
      identity: 'another-user',
      manifestVersion: namespace.manifestVersion,
      rendererVersion: namespace.rendererVersion,
      locale: namespace.locale,
      theme: namespace.theme,
    );
    var unsafe = LiveCacheManifest(
      version: manifest.version,
      scope: manifest.scope,
      identity: manifest.identity,
      strategy: manifest.strategy,
      routes: [
        LiveCacheRoute(
          href: Uri.parse('https://other.example/accounts'),
          maxAge: const Duration(minutes: 5),
          priority: LiveCachePriority.normal,
        ),
      ],
    );

    expect(
      await coordinator.acceptManifest(
        namespace: wrongIdentity,
        manifest: manifest,
      ),
      isFalse,
    );
    expect(
      await coordinator.acceptManifest(namespace: namespace, manifest: unsafe),
      isFalse,
    );
    expect(coordinator.manifest, isNull);
  });

  test('switching users clears the previous namespace', () async {
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(store: store);
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);
    await store.writeSnapshot(
      LiveCacheSnapshot(
        namespace: namespace,
        route: Uri.parse('/accounts'),
        storedAt: storedAt,
        rendered: const {
          's': ['first user'],
        },
      ),
    );
    var nextNamespace = LiveCacheNamespace(
      origin: namespace.origin,
      scope: namespace.scope,
      identity: 'opaque-user-b',
      manifestVersion: namespace.manifestVersion,
      rendererVersion: namespace.rendererVersion,
      locale: namespace.locale,
      theme: namespace.theme,
    );
    var nextManifest = LiveCacheManifest(
      version: manifest.version,
      scope: manifest.scope,
      identity: 'opaque-user-b',
      strategy: manifest.strategy,
      routes: manifest.routes,
    );

    expect(
      await coordinator.acceptManifest(
        namespace: nextNamespace,
        manifest: nextManifest,
      ),
      isTrue,
    );
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
    expect(coordinator.namespace, nextNamespace);
  });

  test('invalidating the active user clears storage and policy', () async {
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(store: store);
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);
    await store.writeSnapshot(
      LiveCacheSnapshot(
        namespace: namespace,
        route: Uri.parse('/accounts'),
        storedAt: storedAt,
        rendered: const {
          's': ['accounts'],
        },
      ),
    );

    expect(await coordinator.invalidateActiveUser(), isTrue);
    expect(coordinator.namespace, isNull);
    expect(coordinator.manifest, isNull);
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
    expect(
      await store.readManifest(
        LiveViewCacheCoordinator.manifestStorageKey(namespace),
      ),
      isNull,
    );
  });

  test('only the latest route and channel ownership can write', () async {
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(
      store: store,
      now: () => storedAt,
    );
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);
    var accountsChannel = Object();
    var accounts =
        coordinator.claimFullRender(
          channel: accountsChannel,
          route: Uri.parse('/accounts'),
        )!;
    var transactions =
        coordinator.claimFullRender(
          channel: Object(),
          route: Uri.parse('/transactions'),
        )!;

    expect(
      await coordinator.storeFullRender(accounts, const {
        's': ['stale accounts'],
      }),
      isFalse,
    );
    expect(
      await coordinator.storeFullRender(transactions, const {
        's': ['fresh transactions'],
      }),
      isTrue,
    );

    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
    expect(
      (await store.readSnapshot(
        namespace,
        Uri.parse('/transactions'),
      ))?.rendered['s'],
      ['fresh transactions'],
    );
  });

  test('undeclared routes cannot claim ownership', () async {
    var coordinator = LiveViewCacheCoordinator(
      store: MemoryLiveViewCacheStore(),
    );
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);

    expect(
      coordinator.claimFullRender(
        channel: Object(),
        route: Uri.parse('/users/settings'),
      ),
      isNull,
    );
  });

  test('loads only fresh snapshots declared by confirmed policy', () async {
    var clock = storedAt;
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(store: store, now: () => clock);
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);
    await store.writeSnapshot(
      LiveCacheSnapshot(
        namespace: namespace,
        route: Uri.parse('/accounts'),
        storedAt: storedAt,
        rendered: const {
          's': ['accounts'],
        },
      ),
    );

    expect(
      await coordinator.loadForNavigation(Uri.parse('/accounts')),
      isNotNull,
    );
    expect(
      await coordinator.loadForNavigation(Uri.parse('/users/settings')),
      isNull,
    );

    clock = storedAt.add(const Duration(minutes: 6));
    expect(await coordinator.loadForNavigation(Uri.parse('/accounts')), isNull);
    expect(await store.readSnapshot(namespace, Uri.parse('/accounts')), isNull);
  });

  test(
    'prefetches missing routes sequentially with high priority first',
    () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(
        store: store,
        now: () => storedAt,
      );
      var prioritizedManifest = LiveCacheManifest(
        version: manifest.version,
        scope: manifest.scope,
        identity: manifest.identity,
        strategy: manifest.strategy,
        routes: [
          manifest.routes.first,
          LiveCacheRoute(
            href: Uri.parse('/dashboard'),
            maxAge: const Duration(minutes: 5),
            priority: LiveCachePriority.high,
          ),
          manifest.routes.last,
        ],
      );
      await coordinator.acceptManifest(
        namespace: namespace,
        manifest: prioritizedManifest,
      );
      await store.writeSnapshot(
        LiveCacheSnapshot(
          namespace: namespace,
          route: Uri.parse('/transactions'),
          storedAt: storedAt,
          rendered: const {
            's': ['already fresh'],
          },
        ),
      );
      var calls = <Uri>[];
      var active = 0;
      var maximumActive = 0;

      var stored = await coordinator.prefetch((route) async {
        calls.add(route);
        active += 1;
        maximumActive = maximumActive < active ? active : maximumActive;
        await Future<void>.delayed(Duration.zero);
        active -= 1;
        return LiveCachePrefetchResult.rendered({
          's': ['prefetched $route'],
        });
      });

      expect(calls, [Uri.parse('/dashboard'), Uri.parse('/accounts')]);
      expect(maximumActive, 1);
      expect(stored, 2);
    },
  );

  test(
    'prefetch stops on authentication loss and supports cancellation',
    () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(store: store);
      await coordinator.acceptManifest(
        namespace: namespace,
        manifest: manifest,
      );
      var calls = <Uri>[];

      expect(
        await coordinator.prefetch((route) async {
          calls.add(route);
          return const LiveCachePrefetchResult.stop();
        }),
        0,
      );
      expect(calls, [Uri.parse('/accounts')]);
      expect(coordinator.namespace, isNull);

      await coordinator.acceptManifest(
        namespace: namespace,
        manifest: manifest,
      );

      var started = Completer<void>();
      var release = Completer<void>();
      var warming = coordinator.prefetch((route) async {
        started.complete();
        await release.future;
        return const LiveCachePrefetchResult.rendered({
          's': ['obsolete'],
        });
      });
      await started.future;
      coordinator.cancelPrefetch();
      release.complete();

      expect(await warming, 0);
      expect(
        await store.readSnapshot(namespace, Uri.parse('/accounts')),
        isNull,
      );
    },
  );

  test(
    'storage errors disable the attempted operation without escaping',
    () async {
      var coordinator = LiveViewCacheCoordinator(store: _ThrowingStore());

      expect(
        await coordinator.acceptManifest(
          namespace: namespace,
          manifest: manifest,
        ),
        isFalse,
      );
      expect(coordinator.manifest, isNull);
    },
  );
}

class _ThrowingStore implements LiveViewCacheStore {
  @override
  Future<void> clear() => throw StateError('unavailable');

  @override
  Future<void> clearNamespace(LiveCacheNamespace namespace) =>
      throw StateError('unavailable');

  @override
  Future<StoredLiveCacheManifest?> readManifest(String key) =>
      throw StateError('unavailable');

  @override
  Future<LiveCacheSnapshot?> readSnapshot(
    LiveCacheNamespace namespace,
    Uri route,
  ) => throw StateError('unavailable');

  @override
  Future<void> removeSnapshot(LiveCacheNamespace namespace, Uri route) =>
      throw StateError('unavailable');

  @override
  Future<void> removeManifest(String key) => throw StateError('unavailable');

  @override
  Future<void> retainRoutes(LiveCacheNamespace namespace, Set<Uri> routes) =>
      throw StateError('unavailable');

  @override
  Future<void> writeManifest(String key, StoredLiveCacheManifest manifest) =>
      throw StateError('unavailable');

  @override
  Future<bool> writeSnapshot(LiveCacheSnapshot snapshot) =>
      throw StateError('unavailable');
}
