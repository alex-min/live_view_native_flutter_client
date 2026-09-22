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

  LiveViewCacheCoordinator({required this.store, DateTime Function()? now})
    : now = now ?? DateTime.now;

  LiveCacheNamespace? get namespace => _namespace;
  LiveCacheManifest? get manifest => _manifest;

  /// Activates policy only after its namespace and routes have been validated
  /// and persisted. Cache failures leave the prior confirmed policy unchanged.
  Future<bool> acceptManifest({
    required LiveCacheNamespace namespace,
    required LiveCacheManifest manifest,
  }) async {
    if (!_matches(namespace, manifest) || !_validRoutes(manifest.routes)) {
      return false;
    }

    try {
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
    return true;
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
  }

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
