import 'dart:async';
import 'dart:convert';

import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot_sanitizer.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/cache/memory_live_view_cache_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PersistentLiveViewCacheStore implements LiveViewCacheStore {
  static const storagePrefix = 'live_view_cache.v1.';
  static const _envelopeVersion = 1;
  static const _manifestPrefix = '${storagePrefix}manifest.';
  static const _namespacePrefix = '${storagePrefix}namespace.';

  final SharedPreferences preferences;
  final int maximumSnapshotBytes;
  final int maximumNamespaceBytes;
  final LiveCacheSnapshotSanitizer sanitizer;
  Future<void> _operationTail = Future<void>.value();

  PersistentLiveViewCacheStore({
    required this.preferences,
    this.maximumSnapshotBytes =
        MemoryLiveViewCacheStore.defaultMaximumSnapshotBytes,
    this.maximumNamespaceBytes =
        MemoryLiveViewCacheStore.defaultMaximumNamespaceBytes,
    this.sanitizer = const LiveCacheSnapshotSanitizer(),
  }) : assert(maximumSnapshotBytes > 0),
       assert(maximumNamespaceBytes > 0);

  static Future<PersistentLiveViewCacheStore> create() async {
    return PersistentLiveViewCacheStore(
      preferences: await SharedPreferences.getInstance(),
    );
  }

  @override
  Future<StoredLiveCacheManifest?> readManifest(String key) async {
    var preferenceKey = _manifestKey(key);
    var envelope = _readMap(preferenceKey);
    if (envelope == null) {
      return null;
    }

    try {
      _requireVersion(envelope);
      var manifest = _manifestFromJson(_requireMap(envelope['manifest']));
      var storedAt = DateTime.parse(_requireString(envelope['storedAt']));
      return StoredLiveCacheManifest(manifest: manifest, storedAt: storedAt);
    } on FormatException {
      await preferences.remove(preferenceKey);
      return null;
    }
  }

  @override
  Future<void> writeManifest(
    String key,
    StoredLiveCacheManifest manifest,
  ) async {
    var envelope = <String, dynamic>{
      'version': _envelopeVersion,
      'storedAt': manifest.storedAt.toUtc().toIso8601String(),
      'manifest': _manifestToJson(manifest.manifest),
    };
    await preferences.setString(_manifestKey(key), jsonEncode(envelope));
  }

  @override
  Future<void> removeManifest(String key) async {
    await preferences.remove(_manifestKey(key));
  }

  @override
  Future<LiveCacheSnapshot?> readSnapshot(
    LiveCacheNamespace namespace,
    Uri route,
  ) => _serialize(() async {
    var preferenceKey = _namespaceKey(namespace);
    var envelope = await _readNamespace(preferenceKey, namespace);
    if (envelope == null) {
      return null;
    }

    var routeKey = route.toString();
    var entries = _requireList(envelope['entries']);
    Map<String, dynamic>? match;
    for (var value in entries) {
      var entry = _requireMap(value);
      if (entry['route'] == routeKey) {
        match = entry;
        break;
      }
    }
    if (match == null) {
      return null;
    }

    try {
      var snapshot = _snapshotFromJson(namespace, match);
      match['lastAccessedAt'] = DateTime.now().toUtc().toIso8601String();
      await preferences.setString(preferenceKey, jsonEncode(envelope));
      return snapshot;
    } on FormatException {
      entries.remove(match);
      await _writeOrRemoveNamespace(preferenceKey, envelope);
      return null;
    }
  });

  @override
  Future<bool> writeSnapshot(LiveCacheSnapshot snapshot) =>
      _serialize(() async {
        if (!_isSafeRelativeRoute(snapshot.route)) {
          return false;
        }
        var rendered = sanitizer.sanitize(snapshot.rendered);
        if (rendered == null) {
          return false;
        }
        var renderedSize = _encodedSize(rendered);
        if (renderedSize == null ||
            renderedSize > maximumSnapshotBytes ||
            renderedSize > maximumNamespaceBytes) {
          return false;
        }

        var preferenceKey = _namespaceKey(snapshot.namespace);
        var envelope = await _readNamespace(preferenceKey, snapshot.namespace);
        envelope ??= <String, dynamic>{
          'version': _envelopeVersion,
          'namespace': _namespaceToJson(snapshot.namespace),
          'entries': <dynamic>[],
        };
        var entries = _requireList(envelope['entries']);
        entries.removeWhere(
          (value) => _routeFromEntry(value) == snapshot.route.toString(),
        );

        while (entries.isNotEmpty &&
            _entriesSize(entries) + renderedSize > maximumNamespaceBytes) {
          entries.sort(_compareLastAccessed);
          entries.removeAt(0);
        }

        entries.add(_snapshotToJson(snapshot, rendered, renderedSize));
        await preferences.setString(preferenceKey, jsonEncode(envelope));
        return true;
      });

  @override
  Future<void> removeSnapshot(LiveCacheNamespace namespace, Uri route) =>
      _serialize(() async {
        var preferenceKey = _namespaceKey(namespace);
        var envelope = await _readNamespace(preferenceKey, namespace);
        if (envelope == null) {
          return;
        }
        _requireList(
          envelope['entries'],
        ).removeWhere((value) => _routeFromEntry(value) == route.toString());
        await _writeOrRemoveNamespace(preferenceKey, envelope);
      });

  @override
  Future<void> retainRoutes(LiveCacheNamespace namespace, Set<Uri> routes) =>
      _serialize(() async {
        var preferenceKey = _namespaceKey(namespace);
        var envelope = await _readNamespace(preferenceKey, namespace);
        if (envelope == null) {
          return;
        }
        var routeKeys = routes.map((route) => route.toString()).toSet();
        _requireList(
          envelope['entries'],
        ).removeWhere((value) => !routeKeys.contains(_routeFromEntry(value)));
        await _writeOrRemoveNamespace(preferenceKey, envelope);
      });

  @override
  Future<void> clearNamespace(LiveCacheNamespace namespace) =>
      _serialize(() async {
        await preferences.remove(_namespaceKey(namespace));
      });

  @override
  Future<void> clear() => _serialize(() async {
    var keys =
        preferences
            .getKeys()
            .where((key) => key.startsWith(storagePrefix))
            .toList();
    for (var key in keys) {
      await preferences.remove(key);
    }
  });

  Future<T> _serialize<T>(Future<T> Function() operation) async {
    var previous = _operationTail;
    var completed = Completer<void>();
    _operationTail = completed.future;
    try {
      try {
        await previous;
      } on Object {
        // A failed operation must not strand later cache operations.
      }
      return await operation();
    } finally {
      completed.complete();
    }
  }

  Map<String, dynamic>? _readMap(String preferenceKey) {
    var encoded = preferences.getString(preferenceKey);
    if (encoded == null) {
      return null;
    }
    try {
      return _requireMap(jsonDecode(encoded));
    } on FormatException {
      preferences.remove(preferenceKey);
      return null;
    }
  }

  Future<Map<String, dynamic>?> _readNamespace(
    String preferenceKey,
    LiveCacheNamespace namespace,
  ) async {
    var envelope = _readMap(preferenceKey);
    if (envelope == null) {
      return null;
    }
    try {
      _requireVersion(envelope);
      if (_namespaceFromJson(_requireMap(envelope['namespace'])) != namespace) {
        throw const FormatException('Cache namespace mismatch');
      }
      var entries = _requireList(envelope['entries']);
      var totalSize = 0;
      for (var value in entries) {
        var entry = _requireMap(value);
        _snapshotFromJson(namespace, entry);
        DateTime.parse(_requireString(entry['lastAccessedAt']));
        totalSize += _requireInt(entry['renderedSize']);
      }
      if (totalSize > maximumNamespaceBytes) {
        throw const FormatException('Cached namespace is oversized');
      }
      return envelope;
    } on FormatException {
      await preferences.remove(preferenceKey);
      return null;
    }
  }

  Future<void> _writeOrRemoveNamespace(
    String preferenceKey,
    Map<String, dynamic> envelope,
  ) async {
    if (_requireList(envelope['entries']).isEmpty) {
      await preferences.remove(preferenceKey);
    } else {
      await preferences.setString(preferenceKey, jsonEncode(envelope));
    }
  }

  void _requireVersion(Map<String, dynamic> envelope) {
    if (envelope['version'] != _envelopeVersion) {
      throw const FormatException('Unsupported cache envelope version');
    }
  }

  String _manifestKey(String key) => '$_manifestPrefix${_encodeKey(key)}';

  String _namespaceKey(LiveCacheNamespace namespace) =>
      '$_namespacePrefix${_encodeKey(jsonEncode(_namespaceToJson(namespace)))}';

  String _encodeKey(String value) => base64Url.encode(utf8.encode(value));

  Map<String, dynamic> _namespaceToJson(LiveCacheNamespace namespace) => {
    'origin': namespace.origin,
    'scope': namespace.scope.name,
    'identity': namespace.identity,
    'manifestVersion': namespace.manifestVersion,
    'rendererVersion': namespace.rendererVersion,
    'locale': namespace.locale,
    'theme': namespace.theme,
  };

  LiveCacheNamespace _namespaceFromJson(Map<String, dynamic> json) =>
      LiveCacheNamespace(
        origin: _requireString(json['origin']),
        scope: _scopeFromName(_requireString(json['scope'])),
        identity: _optionalString(json['identity']),
        manifestVersion: _requireString(json['manifestVersion']),
        rendererVersion: _requireString(json['rendererVersion']),
        locale: _requireString(json['locale']),
        theme: _requireString(json['theme']),
      );

  Map<String, dynamic> _manifestToJson(LiveCacheManifest manifest) => {
    'version': manifest.version,
    'scope': manifest.scope.name,
    'identity': manifest.identity,
    'strategy': manifest.strategy.name,
    'routes':
        manifest.routes
            .map(
              (route) => {
                'href': route.href.toString(),
                'maxAgeSeconds': route.maxAge.inSeconds,
                'priority': route.priority.name,
              },
            )
            .toList(),
  };

  LiveCacheManifest _manifestFromJson(Map<String, dynamic> json) {
    var routes =
        _requireList(json['routes']).map((value) {
          var route = _requireMap(value);
          var href = Uri.parse(_requireString(route['href']));
          var maxAgeSeconds = _requireInt(route['maxAgeSeconds']);
          if (!_isSafeRelativeRoute(href) || maxAgeSeconds <= 0) {
            throw const FormatException('Invalid cached route');
          }
          return LiveCacheRoute(
            href: href,
            maxAge: Duration(seconds: maxAgeSeconds),
            priority: _priorityFromName(_requireString(route['priority'])),
          );
        }).toList();
    if (routes.length > LiveCacheManifest.maximumRouteCount) {
      throw const FormatException('Too many cached routes');
    }

    var scope = _scopeFromName(_requireString(json['scope']));
    var identity = _optionalString(json['identity']);
    if (scope == LiveCacheScope.user &&
        (identity == null || identity.isEmpty)) {
      throw const FormatException('User cache identity is required');
    }
    return LiveCacheManifest(
      version: _requireString(json['version']),
      scope: scope,
      identity: identity,
      strategy: _strategyFromName(_requireString(json['strategy'])),
      routes: routes,
    );
  }

  Map<String, dynamic> _snapshotToJson(
    LiveCacheSnapshot snapshot,
    Map<String, dynamic> rendered,
    int renderedSize,
  ) {
    var timestamp = DateTime.now().toUtc().toIso8601String();
    return {
      'route': snapshot.route.toString(),
      'storedAt': snapshot.storedAt.toUtc().toIso8601String(),
      'lastAccessedAt': timestamp,
      'renderedSize': renderedSize,
      'rendered': rendered,
    };
  }

  LiveCacheSnapshot _snapshotFromJson(
    LiveCacheNamespace namespace,
    Map<String, dynamic> json,
  ) {
    var route = Uri.parse(_requireString(json['route']));
    var rendered = _requireMap(json['rendered']);
    var renderedSize = _encodedSize(rendered);
    if (!_isSafeRelativeRoute(route) ||
        renderedSize == null ||
        renderedSize != _requireInt(json['renderedSize']) ||
        renderedSize > maximumSnapshotBytes) {
      throw const FormatException('Invalid cached snapshot');
    }
    return LiveCacheSnapshot(
      namespace: namespace,
      route: route,
      storedAt: DateTime.parse(_requireString(json['storedAt'])),
      rendered: rendered,
    );
  }

  int _compareLastAccessed(dynamic left, dynamic right) {
    var leftValue = _requireMap(left)['lastAccessedAt'];
    var rightValue = _requireMap(right)['lastAccessedAt'];
    return _requireString(leftValue).compareTo(_requireString(rightValue));
  }

  int _entriesSize(List<dynamic> entries) => entries.fold(
    0,
    (total, value) => total + _requireInt(_requireMap(value)['renderedSize']),
  );

  String? _routeFromEntry(dynamic value) {
    try {
      return _requireString(_requireMap(value)['route']);
    } on FormatException {
      return null;
    }
  }

  int? _encodedSize(Map<String, dynamic> rendered) {
    try {
      return utf8.encode(jsonEncode(rendered)).length;
    } on JsonUnsupportedObjectError {
      return null;
    }
  }

  bool _isSafeRelativeRoute(Uri route) =>
      !route.hasScheme &&
      !route.hasAuthority &&
      route.fragment.isEmpty &&
      route.path.startsWith('/');

  Map<String, dynamic> _requireMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Expected a JSON object');
    }
    return value;
  }

  List<dynamic> _requireList(dynamic value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected a JSON list');
    }
    return value;
  }

  String _requireString(dynamic value) {
    if (value is! String) {
      throw const FormatException('Expected a string');
    }
    return value;
  }

  String? _optionalString(dynamic value) {
    if (value != null && value is! String) {
      throw const FormatException('Expected a nullable string');
    }
    return value as String?;
  }

  int _requireInt(dynamic value) {
    if (value is! int) {
      throw const FormatException('Expected an integer');
    }
    return value;
  }

  LiveCacheScope _scopeFromName(String name) =>
      LiveCacheScope.values.where((value) => value.name == name).firstOrNull ??
      (throw const FormatException('Unknown cache scope'));

  LiveCacheStrategy _strategyFromName(String name) =>
      LiveCacheStrategy.values
          .where((value) => value.name == name)
          .firstOrNull ??
      (throw const FormatException('Unknown cache strategy'));

  LiveCachePriority _priorityFromName(String name) =>
      LiveCachePriority.values
          .where((value) => value.name == name)
          .firstOrNull ??
      (throw const FormatException('Unknown cache priority'));
}
