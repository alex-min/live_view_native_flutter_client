import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';

void main() {
  LiveCacheNamespace namespace({
    String origin = 'https://finance.example',
    LiveCacheScope scope = LiveCacheScope.user,
    String? identity = 'user-a',
    String manifestVersion = 'manifest-v1',
    String rendererVersion = 'renderer-v1',
    String locale = 'en',
    String theme = 'cosmic-light',
  }) => LiveCacheNamespace(
    origin: origin,
    scope: scope,
    identity: identity,
    manifestVersion: manifestVersion,
    rendererVersion: rendererVersion,
    locale: locale,
    theme: theme,
  );

  test('equal cache dimensions produce the same namespace', () {
    expect(namespace(), namespace());
    expect(namespace().hashCode, namespace().hashCode);
  });

  test('every presentation and identity dimension separates namespaces', () {
    var base = namespace();

    expect(namespace(origin: 'https://other.example'), isNot(base));
    expect(namespace(scope: LiveCacheScope.public), isNot(base));
    expect(namespace(identity: 'user-b'), isNot(base));
    expect(namespace(manifestVersion: 'manifest-v2'), isNot(base));
    expect(namespace(rendererVersion: 'renderer-v2'), isNot(base));
    expect(namespace(locale: 'fr'), isNot(base));
    expect(namespace(theme: 'cosmic-dark'), isNot(base));
  });
}
