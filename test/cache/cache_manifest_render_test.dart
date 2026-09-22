import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('cache metadata is accepted without rendering a widget', (
    tester,
  ) async {
    var view = LiveView();

    view.handleRenderedMessage({
      's': [
        '''
        <flutter>
          <live-cache-manifest
            version="finance-v1"
            scope="user"
            identity="opaque-user"
            strategy="stale-while-revalidate"
          >
            <live-cache-route href="/dashboard" max-age="300" priority="high" />
            <live-cache-route href="/accounts" max-age="300" priority="normal" />
          </live-cache-manifest>
          <viewBody><Text>Accounts</Text></viewBody>
        </flutter>
        ''',
      ],
    });

    await tester.runLiveView(view);

    expect(find.text('Accounts'), findsOneWidget);
    expect(find.byType(SizedBox), findsWidgets);
    expect(view.cacheManifest, isNotNull);
    expect(view.cacheManifest!.version, 'finance-v1');
    expect(view.cacheManifest!.scope, LiveCacheScope.user);
    expect(view.cacheManifest!.routes, hasLength(2));
  });

  test('a malformed current manifest disables the previous policy', () {
    var view = LiveView();

    view.handleRenderedMessage({
      's': [
        '''
        <flutter>
          <live-cache-manifest
            version="finance-v1"
            scope="public"
            strategy="stale-while-revalidate"
          />
          <viewBody><Text>Accounts</Text></viewBody>
        </flutter>
        ''',
      ],
    });
    expect(view.cacheManifest, isNotNull);

    view.handleRenderedMessage({
      's': [
        '''
        <flutter>
          <live-cache-manifest
            version="finance-v1"
            scope="user"
            strategy="stale-while-revalidate"
          />
          <viewBody><Text>Accounts</Text></viewBody>
        </flutter>
        ''',
      ],
    });

    expect(view.cacheManifest, isNull);
  });
}
