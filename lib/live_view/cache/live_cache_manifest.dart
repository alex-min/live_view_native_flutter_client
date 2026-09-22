enum LiveCacheScope { public, user, memory }

enum LiveCacheStrategy { staleWhileRevalidate }

enum LiveCachePriority { normal, high }

class LiveCacheRoute {
  final Uri href;
  final Duration maxAge;
  final LiveCachePriority priority;

  const LiveCacheRoute({
    required this.href,
    required this.maxAge,
    required this.priority,
  });
}

class LiveCacheManifest {
  static const maximumRouteCount = 16;

  final String version;
  final LiveCacheScope scope;
  final String? identity;
  final LiveCacheStrategy strategy;
  final List<LiveCacheRoute> routes;

  const LiveCacheManifest({
    required this.version,
    required this.scope,
    required this.identity,
    required this.strategy,
    required this.routes,
  });
}
