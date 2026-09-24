import 'dart:convert';

import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';

class LiveViewCacheCoordinator {
  final LiveViewCacheStore store;
  final DateTime Function() now;

  LiveCacheNamespace? _namespace;
  LiveCacheManifest? _manifest;
  LiveCacheRenderOwnership? _activeRender;
  int _prefetchGeneration = 0;

  LiveViewCacheCoordinator({required this.store, DateTime Function()? now})
    : now = now ?? DateTime.now;

  LiveCacheNamespace? get namespace => _namespace;
  LiveCacheManifest? get manifest => _manifest;

  bool hasRoute(Uri route) =>
      _manifest?.routes.any((candidate) => candidate.href == route) ?? false;

  Future<LiveCacheSnapshot?> loadForNavigation(Uri route) =>
      _loadSnapshot(route, allowStale: true);

  Future<LiveCacheSnapshot?> _loadSnapshot(
    Uri route, {
    required bool allowStale,
  }) async {
    var namespace = _namespace;
    var manifest = _manifest;
    if (namespace == null || manifest == null) {
      return null;
    }
    LiveCacheRoute? policy;
    for (var candidate in manifest.routes) {
      if (candidate.href == route) {
        policy = candidate;
        break;
      }
    }
    if (policy == null) {
      return null;
    }

    try {
      var snapshot = await store.readSnapshot(namespace, route);
      if (snapshot == null) {
        return null;
      }
      var age = now().toUtc().difference(snapshot.storedAt.toUtc());
      if (age.isNegative) {
        await store.removeSnapshot(namespace, route);
        return null;
      }
      if (!allowStale && age > policy.maxAge) {
        return null;
      }
      return snapshot;
    } on Object {
      return null;
    }
  }

  /// Activates policy only after its namespace and routes have been validated
  /// and persisted. Cache failures leave the prior confirmed policy unchanged.
  Future<bool> acceptManifest({
    required LiveCacheNamespace namespace,
    required LiveCacheManifest manifest,
  }) async {
    if (!_matches(namespace, manifest) || !_validRoutes(manifest.routes)) {
      return false;
    }

    var priorNamespace = _namespace;
    var changesUser = _changesUser(priorNamespace, namespace);
    if (changesUser) {
      deactivate();
    }
    try {
      if (changesUser) {
        await store.clearNamespace(priorNamespace!);
        await store.removeManifest(manifestStorageKey(priorNamespace));
      }
      await store.writeManifest(
        manifestStorageKey(namespace),
        StoredLiveCacheManifest(manifest: manifest, storedAt: now().toUtc()),
      );
      await store.retainRoutes(
        namespace,
        manifest.routes.map((route) => route.href).toSet(),
      );
    } on Object {
      return false;
    }

    _namespace = namespace;
    _manifest = manifest;
    _activeRender = null;
    _prefetchGeneration += 1;
    return true;
  }

  /// Warms missing or expired declared routes by priority tier. Routes within
  /// a tier run together so a frequently interrupted warm-up cannot starve
  /// routes near the end of the manifest. The caller owns transport and
  /// document extraction so this coordinator remains reusable and cannot
  /// mutate the active LiveView session.
  Future<int> prefetch(
    Future<LiveCachePrefetchResult> Function(Uri route) fetch,
  ) async {
    var namespace = _namespace;
    var manifest = _manifest;
    if (namespace == null || manifest == null) {
      return 0;
    }
    var generation = ++_prefetchGeneration;
    var storedCount = 0;

    for (var priority in [LiveCachePriority.high, LiveCachePriority.normal]) {
      var routes = manifest.routes.where((route) => route.priority == priority);
      var results = await Future.wait(
        routes.map(
          (policy) => _prefetchRoute(
            policy,
            generation: generation,
            namespace: namespace,
            manifest: manifest,
            fetch: fetch,
          ),
        ),
      );
      storedCount += results.where((result) => result).length;
      if (!_ownsPrefetch(generation, namespace, manifest)) {
        break;
      }
    }
    return storedCount;
  }

  Future<bool> _prefetchRoute(
    LiveCacheRoute policy, {
    required int generation,
    required LiveCacheNamespace namespace,
    required LiveCacheManifest manifest,
    required Future<LiveCachePrefetchResult> Function(Uri route) fetch,
  }) async {
    if (!_ownsPrefetch(generation, namespace, manifest)) {
      return false;
    }
    var existing = await _loadSnapshot(policy.href, allowStale: false);
    if (!_ownsPrefetch(generation, namespace, manifest) || existing != null) {
      return false;
    }

    LiveCachePrefetchResult result;
    try {
      result = await fetch(policy.href);
    } on Object {
      return false;
    }
    if (!_ownsPrefetch(generation, namespace, manifest)) {
      return false;
    }
    if (result.stop) {
      await invalidateActiveUser();
      return false;
    }
    var rendered = result.rendered;
    if (rendered == null) {
      return false;
    }
    try {
      return await store.writeSnapshot(
        LiveCacheSnapshot(
          namespace: namespace,
          route: policy.href,
          storedAt: now().toUtc(),
          rendered: rendered,
        ),
      );
    } on Object {
      // Cache warming is best-effort and must never affect live navigation.
      return false;
    }
  }

  void cancelPrefetch() {
    _prefetchGeneration += 1;
  }

  /// Claims the next full render for one exact channel and canonical route.
  /// A later claim supersedes this opaque token.
  LiveCacheRenderOwnership? claimFullRender({
    required Object channel,
    required Uri route,
  }) {
    var namespace = _namespace;
    var manifest = _manifest;
    if (namespace == null ||
        manifest == null ||
        !manifest.routes.any((candidate) => candidate.href == route)) {
      return null;
    }

    var ownership = LiveCacheRenderOwnership._(
      namespace: namespace,
      route: route,
      channel: channel,
    );
    _activeRender = ownership;
    return ownership;
  }

  void abandonRender(LiveCacheRenderOwnership ownership) {
    if (identical(_activeRender, ownership)) {
      _activeRender = null;
    }
  }

  /// Stores only the full render belonging to the latest route/channel claim.
  /// Diffs never enter this API and superseded channels cannot reuse a token.
  Future<bool> storeFullRender(
    LiveCacheRenderOwnership ownership,
    Map<String, dynamic> rendered,
  ) async {
    if (!identical(_activeRender, ownership) ||
        _namespace != ownership.namespace) {
      return false;
    }

    try {
      var stored = await store.writeSnapshot(
        LiveCacheSnapshot(
          namespace: ownership.namespace,
          route: ownership.route,
          storedAt: now().toUtc(),
          rendered: rendered,
        ),
      );
      if (identical(_activeRender, ownership)) {
        _activeRender = null;
      }
      return stored;
    } on Object {
      if (identical(_activeRender, ownership)) {
        _activeRender = null;
      }
      return false;
    }
  }

  void deactivate() {
    _namespace = null;
    _manifest = null;
    _activeRender = null;
    _prefetchGeneration += 1;
  }

  Future<bool> invalidateActiveUser() async {
    var namespace = _namespace;
    deactivate();
    if (namespace == null || namespace.scope != LiveCacheScope.user) {
      return true;
    }
    try {
      await store.clearNamespace(namespace);
      await store.removeManifest(manifestStorageKey(namespace));
      return true;
    } on Object {
      return false;
    }
  }

  bool _ownsPrefetch(
    int generation,
    LiveCacheNamespace namespace,
    LiveCacheManifest manifest,
  ) =>
      generation == _prefetchGeneration &&
      _namespace == namespace &&
      identical(_manifest, manifest);

  static String manifestStorageKey(LiveCacheNamespace namespace) => jsonEncode([
    namespace.origin,
    namespace.rendererVersion,
    namespace.locale,
    namespace.theme,
  ]);

  bool _matches(LiveCacheNamespace namespace, LiveCacheManifest manifest) =>
      namespace.scope == manifest.scope &&
      namespace.identity == manifest.identity &&
      namespace.manifestVersion == manifest.version;

  bool _changesUser(LiveCacheNamespace? current, LiveCacheNamespace next) =>
      current != null &&
      current.scope == LiveCacheScope.user &&
      next.scope == LiveCacheScope.user &&
      (current.origin != next.origin || current.identity != next.identity);

  bool _validRoutes(List<LiveCacheRoute> routes) {
    if (routes.length > LiveCacheManifest.maximumRouteCount) {
      return false;
    }
    var seen = <String>{};
    for (var route in routes) {
      var href = route.href;
      if (href.hasScheme ||
          href.hasAuthority ||
          href.fragment.isNotEmpty ||
          !href.path.startsWith('/') ||
          route.maxAge <= Duration.zero ||
          !seen.add(href.toString())) {
        return false;
      }
    }
    return true;
  }
}

class LiveCachePrefetchResult {
  final Map<String, dynamic>? rendered;
  final bool stop;

  const LiveCachePrefetchResult.rendered(Map<String, dynamic> this.rendered)
    : stop = false;

  const LiveCachePrefetchResult.skip() : rendered = null, stop = false;

  const LiveCachePrefetchResult.stop() : rendered = null, stop = true;
}

class LiveCacheRenderOwnership {
  final LiveCacheNamespace namespace;
  final Uri route;
  final Object channel;

  const LiveCacheRenderOwnership._({
    required this.namespace,
    required this.route,
    required this.channel,
  });
}
