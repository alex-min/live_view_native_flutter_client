import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest_parser.dart';
import 'package:xml/xml.dart';

void main() {
  const parser = LiveCacheManifestParser();

  XmlElement manifestElement(String source) =>
      XmlDocument.parse(source).rootElement;

  test('extracts a manifest beside other top-level layout elements', () {
    var manifest = parser.parseRendered({
      's': [
        '<csrf-token value="token" />'
            '<flutter><live-cache-manifest version="finance-v1" '
            'scope="user" identity="opaque-user" '
            'strategy="stale-while-revalidate">'
            '<live-cache-route href="/accounts" max-age="300" />'
            '</live-cache-manifest><viewBody /></flutter>',
      ],
    });

    expect(manifest?.identity, 'opaque-user');
    expect(manifest?.routes.single.href.toString(), '/accounts');
  });

  test('accepts matching root and page manifests in one HTTP render', () {
    var manifest = parser.parseRendered({
      's': [
        '<live-cache-manifest version="finance-v1" scope="public" '
            'strategy="stale-while-revalidate" />'
            '<flutter><live-cache-manifest version="finance-v1" '
            'scope="public" strategy="stale-while-revalidate" /></flutter>',
      ],
    });

    expect(manifest?.scope, LiveCacheScope.public);
  });

  test('rejects conflicting root and page manifests', () {
    var manifest = parser.parseRendered({
      's': [
        '<live-cache-manifest version="finance-v1" scope="public" '
            'strategy="stale-while-revalidate" />'
            '<flutter><live-cache-manifest version="finance-v2" '
            'scope="public" strategy="stale-while-revalidate" /></flutter>',
      ],
    });

    expect(manifest, isNull);
  });

  test('parses a user-scoped stale-while-revalidate manifest', () {
    var manifest = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="finance-v1"
          scope="user"
          identity="opaque-user"
          strategy="stale-while-revalidate"
          future-attribute="ignored"
        >
          <live-cache-route href="/dashboard" max-age="300" priority="high" />
          <live-cache-route href="/transactions?page=2" max-age="900" />
        </live-cache-manifest>
      '''),
    );

    expect(manifest, isNotNull);
    expect(manifest!.version, 'finance-v1');
    expect(manifest.scope, LiveCacheScope.user);
    expect(manifest.identity, 'opaque-user');
    expect(manifest.strategy, LiveCacheStrategy.staleWhileRevalidate);
    expect(manifest.routes, hasLength(2));
    expect(manifest.routes.first.href.toString(), '/dashboard');
    expect(manifest.routes.first.maxAge, const Duration(minutes: 5));
    expect(manifest.routes.first.priority, LiveCachePriority.high);
    expect(manifest.routes.last.href.toString(), '/transactions?page=2');
    expect(manifest.routes.last.priority, LiveCachePriority.normal);
  });

  test('requires an opaque identity for user scope', () {
    var manifest = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="1"
          scope="user"
          strategy="stale-while-revalidate"
        >
          <live-cache-route href="/accounts" max-age="300" />
        </live-cache-manifest>
      '''),
    );

    expect(manifest, isNull);
  });

  test('allows public and memory manifests without an identity', () {
    for (var scope in ['public', 'memory']) {
      var manifest = parser.parse(
        manifestElement('''
          <live-cache-manifest
            version="1"
            scope="$scope"
            strategy="stale-while-revalidate"
          />
        '''),
      );

      expect(manifest, isNotNull);
      expect(manifest!.identity, isNull);
    }
  });

  test('rejects external, protocol-relative, and fragment routes', () {
    for (var href in [
      'https://example.com/accounts',
      '//example.com/accounts',
      'accounts',
      '/accounts#balance',
    ]) {
      var manifest = parser.parse(
        manifestElement('''
          <live-cache-manifest
            version="1"
            scope="public"
            strategy="stale-while-revalidate"
          >
            <live-cache-route href="$href" max-age="300" />
          </live-cache-manifest>
        '''),
      );

      expect(manifest, isNull, reason: '$href must not be cacheable');
    }
  });

  test('rejects invalid route policy instead of partially applying it', () {
    for (var route in [
      '<live-cache-route href="/accounts" max-age="0" />',
      '<live-cache-route href="/accounts" max-age="later" />',
      '<live-cache-route href="/accounts" max-age="300" priority="urgent" />',
      '<unexpected-route href="/accounts" max-age="300" />',
    ]) {
      var manifest = parser.parse(
        manifestElement('''
          <live-cache-manifest
            version="1"
            scope="public"
            strategy="stale-while-revalidate"
          >
            $route
          </live-cache-manifest>
        '''),
      );

      expect(manifest, isNull, reason: '$route must invalidate the manifest');
    }
  });

  test('rejects duplicate routes', () {
    var manifest = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="1"
          scope="public"
          strategy="stale-while-revalidate"
        >
          <live-cache-route href="/accounts" max-age="300" />
          <live-cache-route href="/accounts" max-age="600" />
        </live-cache-manifest>
      '''),
    );

    expect(manifest, isNull);
  });

  test('rejects manifests above the route limit', () {
    var routes =
        List.generate(
          LiveCacheManifest.maximumRouteCount + 1,
          (index) => '<live-cache-route href="/route-$index" max-age="300" />',
        ).join();

    var manifest = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="1"
          scope="public"
          strategy="stale-while-revalidate"
        >
          $routes
        </live-cache-manifest>
      '''),
    );

    expect(manifest, isNull);
  });

  test('rejects unsupported scope and strategy values', () {
    var unsupportedScope = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="1"
          scope="device"
          strategy="stale-while-revalidate"
        />
      '''),
    );
    var unsupportedStrategy = parser.parse(
      manifestElement('''
        <live-cache-manifest
          version="1"
          scope="public"
          strategy="cache-first"
        />
      '''),
    );

    expect(unsupportedScope, isNull);
    expect(unsupportedStrategy, isNull);
  });

  test('ignores elements that are not cache manifests', () {
    expect(parser.parse(manifestElement('<flutter />')), isNull);
  });
}
