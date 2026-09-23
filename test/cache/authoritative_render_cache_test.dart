import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_coordinator.dart';
import 'package:liveview_flutter/live_view/cache/memory_live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  const rendered = {
    's': [
      '<flutter><live-cache-manifest version="finance-v1" scope="user" '
          'identity="opaque-user" strategy="stale-while-revalidate">'
          '<live-cache-route href="/accounts" max-age="300" />'
          '</live-cache-manifest><Text>Accounts</Text></flutter>',
    ],
  };

  test(
    'stores only a full render delivered by the current joined channel',
    () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(store: store);
      var (view, server) = await connect(
        LiveView(cacheCoordinator: coordinator),
        url: 'http://localhost:9999/accounts',
      );
      var channel = server.lastChannel!;

      view.handleMessage(
        Message(
          event: PhoenixChannelEvent('phx_reply'),
          payload: {
            'response': {'rendered': rendered},
          },
        ),
        sourceChannel: channel,
      );
      await Future<void>.delayed(Duration.zero);

      var namespace = coordinator.namespace!;
      var snapshot = await store.readSnapshot(
        namespace,
        Uri.parse('/accounts'),
      );
      expect(snapshot?.rendered, rendered);
    },
  );

  test('direct and dead-view renders are never persisted', () async {
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(store: store);
    var (view, _) = await connect(
      LiveView(cacheCoordinator: coordinator),
      url: 'http://localhost:9999/accounts',
    );

    view.handleRenderedMessage(rendered);
    view.handleRenderedMessage(rendered, viewType: ViewType.deadView);
    await Future<void>.delayed(Duration.zero);

    expect(coordinator.namespace, isNull);
  });
}
