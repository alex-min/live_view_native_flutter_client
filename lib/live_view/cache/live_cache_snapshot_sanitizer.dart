class LiveCacheSnapshotSanitizer {
  static const maximumDepth = 64;
  static const maximumNodes = 100000;

  const LiveCacheSnapshotSanitizer();

  /// Returns a detached JSON-compatible copy, or `null` when [rendered]
  /// contains connection bootstrap material or cannot be stored safely.
  Map<String, dynamic>? sanitize(Map<String, dynamic> rendered) {
    var state = _SanitizerState();
    var sanitized = _sanitizeValue(rendered, state, 0);
    return sanitized is Map<String, dynamic> ? sanitized : null;
  }

  dynamic _sanitizeValue(dynamic value, _SanitizerState state, int depth) {
    state.nodes += 1;
    if (depth > maximumDepth || state.nodes > maximumNodes) {
      return _unsafe;
    }
    if (value == null || value is bool || value is int) {
      return value;
    }
    if (value is double) {
      return value.isFinite ? value : _unsafe;
    }
    if (value is String) {
      return _containsBootstrapMaterial(value) ? _unsafe : value;
    }
    if (value is List) {
      var sanitized = <dynamic>[];
      for (var item in value) {
        var result = _sanitizeValue(item, state, depth + 1);
        if (identical(result, _unsafe)) {
          return _unsafe;
        }
        sanitized.add(result);
      }
      return sanitized;
    }
    if (value is Map) {
      var sanitized = <String, dynamic>{};
      for (var entry in value.entries) {
        var key = entry.key;
        if (key is! String || _isForbiddenKey(key)) {
          return _unsafe;
        }
        var result = _sanitizeValue(entry.value, state, depth + 1);
        if (identical(result, _unsafe)) {
          return _unsafe;
        }
        sanitized[key] = result;
      }
      return sanitized;
    }
    return _unsafe;
  }

  bool _isForbiddenKey(String key) {
    var normalized = key
        .trim()
        .replaceAll('_', '-')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match[1]}-${match[2]}',
        )
        .toLowerCase()
        .replaceFirst(RegExp(r'^-+'), '');
    return const {
      'csrf',
      'csrf-token',
      'data-phx-session',
      'phx-session',
      'data-phx-static',
      'phx-static',
      'cookie',
      'cookies',
      'set-cookie',
      'live-view-id',
      'liveview-id',
    }.contains(normalized);
  }

  bool _containsBootstrapMaterial(String value) {
    return RegExp(
      r'''data-phx-(?:session|static)\s*=|data-phx-main(?:\s|=|>)|_csrf_token|name\s*=\s*["']csrf-token|csrf-token\s*=|<csrf-token\b|document\.cookie|(?:^|[\r\n])\s*(?:set-)?cookie\s*:|(?:^|[\s<])(?:set-)?cookie\s*=''',
      caseSensitive: false,
    ).hasMatch(value);
  }
}

class _SanitizerState {
  int nodes = 0;
}

const _unsafe = Object();
