import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';

class StoredLiveCacheManifest {
  final LiveCacheManifest manifest;
  final DateTime storedAt;

  const StoredLiveCacheManifest({
    required this.manifest,
    required this.storedAt,
  });
}

abstract interface class LiveViewCacheStore {
  Future<StoredLiveCacheManifest?> readManifest(String key);

  Future<void> writeManifest(String key, StoredLiveCacheManifest manifest);

  Future<void> removeManifest(String key);

  Future<LiveCacheSnapshot?> readSnapshot(
    LiveCacheNamespace namespace,
    Uri route,
  );

  Future<bool> writeSnapshot(LiveCacheSnapshot snapshot);

  Future<void> removeSnapshot(LiveCacheNamespace namespace, Uri route);

  Future<void> retainRoutes(LiveCacheNamespace namespace, Set<Uri> routes);

  Future<void> clearNamespace(LiveCacheNamespace namespace);

  Future<void> clear();
}
