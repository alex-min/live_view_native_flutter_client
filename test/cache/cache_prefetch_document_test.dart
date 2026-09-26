import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_prefetch_document.dart';

void main() {
  const namespace = LiveCacheNamespace(
    origin: 'https://finance.example',
    scope: LiveCacheScope.user,
    identity: 'opaque-user',
    manifestVersion: 'finance-v1',
    rendererVersion: '1',
    locale: 'en',
    theme: 'cosmic/light',
  );
  const extractor = LiveCachePrefetchDocument();

  test('extracts presentation without bootstrap credentials', () {
    var result = extractor.extract(
      '<meta name="csrf-token" content="secret">'
      '<div id="phx-root" data-phx-main data-phx-session="signed" '
      'data-phx-static="static">'
      '<flutter><live-cache-manifest version="finance-v1" scope="user" '
      'identity="opaque-user" strategy="stale-while-revalidate">'
      '<live-cache-route href="/accounts" max-age="300">'
      '</live-cache-route></live-cache-manifest>'
      '<hidden name="_csrf_token" value="secret"></hidden>'
      '<viewBody><Text>Accounts</Text></viewBody></flutter></div>',
      namespace: namespace,
    );

    expect(result.policyConfirmed, isTrue);
    var markup = (result.rendered!['s'] as List).single as String;
    expect(markup, contains('Accounts'));
    expect(markup, contains('<Text>Accounts</Text>'));
    expect(markup, isNot(contains('secret')));
    expect(markup, isNot(contains('data-phx')));
    expect(markup, isNot(contains('phx-root')));
  });

  test('rejects documents from another or unauthenticated policy', () {
    var missing = extractor.extract(
      '<div data-phx-main><flutter><Text>Log in</Text></flutter></div>',
      namespace: namespace,
    );
    var anotherUser = extractor.extract(
      '<div data-phx-main><flutter>'
      '<live-cache-manifest version="finance-v1" scope="user" '
      'identity="another-user" strategy="stale-while-revalidate">'
      '</live-cache-manifest></flutter></div>',
      namespace: namespace,
    );

    expect(missing.policyConfirmed, isFalse);
    expect(missing.sessionChanged, isFalse);
    expect(anotherUser.policyConfirmed, isFalse);
    expect(anotherUser.sessionChanged, isTrue);
  });

  test('fails closed when presentation still contains forbidden material', () {
    var result = extractor.extract(
      '<div data-phx-main><flutter>'
      '<live-cache-manifest version="finance-v1" scope="user" '
      'identity="opaque-user" strategy="stale-while-revalidate">'
      '</live-cache-manifest>'
      '<Text>document.cookie</Text></flutter></div>',
      namespace: namespace,
    );

    expect(result.policyConfirmed, isTrue);
    expect(result.rendered, isNull);
  });
}
