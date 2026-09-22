import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';

class LiveCacheSnapshot {
  final LiveCacheNamespace namespace;
  final Uri route;
  final DateTime storedAt;
  final Map<String, dynamic> rendered;

  LiveCacheSnapshot({
    required this.namespace,
    required this.route,
    required this.storedAt,
    required Map<String, dynamic> rendered,
  }) : rendered = Map.unmodifiable(rendered);
}
