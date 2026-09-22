import 'dart:collection';
import 'dart:convert';

import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';

class MemoryLiveViewCacheStore implements LiveViewCacheStore {
  static const defaultMaximumSnapshotBytes = 512 * 1024;
  static const defaultMaximumNamespaceBytes = 4 * 1024 * 1024;

  final int maximumSnapshotBytes;
  final int maximumNamespaceBytes;

  final Map<String, StoredLiveCacheManifest> _manifests = {};
  final Map<LiveCacheNamespace, LinkedHashMap<String, _MemorySnapshot>>
  _snapshots = {};

  MemoryLiveViewCacheStore({
    this.maximumSnapshotBytes = defaultMaximumSnapshotBytes,
    this.maximumNamespaceBytes = defaultMaximumNamespaceBytes,
  }) : assert(maximumSnapshotBytes > 0),
       assert(maximumNamespaceBytes > 0);

  @override
  Future<StoredLiveCacheManifest?> readManifest(String key) async =>
      _manifests[key];

  @override
  Future<void> writeManifest(
    String key,
    StoredLiveCacheManifest manifest,
  ) async {
    _manifests[key] = manifest;
  }

  @override
  Future<LiveCacheSnapshot?> readSnapshot(
    LiveCacheNamespace namespace,
    Uri route,
  ) async {
    var entries = _snapshots[namespace];
    var routeKey = route.toString();
    var entry = entries?.remove(routeKey);
    if (entry == null) {
      return null;
    }

    // Reinsert on access so the LinkedHashMap keeps least-recently-used
    // entries at the front.
    entries![routeKey] = entry;
    return entry.snapshot;
  }

  @override
  Future<bool> writeSnapshot(LiveCacheSnapshot snapshot) async {
    var size = _encodedSize(snapshot.rendered);
    if (size == null ||
        size > maximumSnapshotBytes ||
        size > maximumNamespaceBytes) {
      return false;
    }

    var entries = _snapshots.putIfAbsent(snapshot.namespace, LinkedHashMap.new);
    var routeKey = snapshot.route.toString();
    entries.remove(routeKey);

    while (entries.isNotEmpty &&
        _totalSize(entries) + size > maximumNamespaceBytes) {
      entries.remove(entries.keys.first);
    }

    entries[routeKey] = _MemorySnapshot(snapshot: snapshot, size: size);
    return true;
  }

  @override
  Future<void> removeSnapshot(LiveCacheNamespace namespace, Uri route) async {
    var entries = _snapshots[namespace];
    entries?.remove(route.toString());
    if (entries?.isEmpty == true) {
      _snapshots.remove(namespace);
    }
  }

  @override
  Future<void> retainRoutes(
    LiveCacheNamespace namespace,
    Set<Uri> routes,
  ) async {
    var entries = _snapshots[namespace];
    if (entries == null) {
      return;
    }

    var routeKeys = routes.map((route) => route.toString()).toSet();
    entries.removeWhere((key, _) => !routeKeys.contains(key));
    if (entries.isEmpty) {
      _snapshots.remove(namespace);
    }
  }

  @override
  Future<void> clearNamespace(LiveCacheNamespace namespace) async {
    _snapshots.remove(namespace);
  }

  @override
  Future<void> clear() async {
    _manifests.clear();
    _snapshots.clear();
  }

  int? _encodedSize(Map<String, dynamic> rendered) {
    try {
      return utf8.encode(jsonEncode(rendered)).length;
    } on JsonUnsupportedObjectError {
      return null;
    }
  }

  int _totalSize(LinkedHashMap<String, _MemorySnapshot> entries) =>
      entries.values.fold(0, (total, entry) => total + entry.size);
}

class _MemorySnapshot {
  final LiveCacheSnapshot snapshot;
  final int size;

  const _MemorySnapshot({required this.snapshot, required this.size});
}
