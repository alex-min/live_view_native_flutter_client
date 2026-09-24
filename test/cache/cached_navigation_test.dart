import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
import 'package:liveview_flutter/live_view/cache/live_view_cache_coordinator.dart';
import 'package:liveview_flutter/live_view/cache/memory_live_view_cache_store.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('shows a fresh snapshot until the target channel renders', (
    tester,
  ) async {
    var store = MemoryLiveViewCacheStore();
    var coordinator = LiveViewCacheCoordinator(store: store);
    var view = LiveView(cacheCoordinator: coordinator);
    var (_, server) = await connect(view);
    await tester.runLiveView(view);

    var route = Uri.parse('/accounts');
    var manifest = LiveCacheManifest(
      version: 'finance-v1',
      scope: LiveCacheScope.user,
      identity: 'opaque-user',
      strategy: LiveCacheStrategy.staleWhileRevalidate,
      routes: [
        LiveCacheRoute(
          href: route,
          maxAge: const Duration(minutes: 5),
          priority: LiveCachePriority.normal,
        ),
      ],
    );
    var namespace = const LiveCacheNamespace(
      origin: 'http://localhost:9999',
      scope: LiveCacheScope.user,
      identity: 'opaque-user',
      manifestVersion: 'finance-v1',
      rendererVersion: LiveView.cacheRendererVersion,
      locale: 'en',
      theme: 'cosmic/light',
    );
    await coordinator.acceptManifest(namespace: namespace, manifest: manifest);
    await store.writeSnapshot(
      LiveCacheSnapshot(
        namespace: namespace,
        route: route,
        storedAt: DateTime.now(),
        rendered: {
          's': [
            '<flutter><live-cache-manifest version="finance-v1" '
                'scope="user" identity="opaque-user" '
                'strategy="stale-while-revalidate">'
                '<live-cache-route href="/accounts" max-age="300" />'
                '</live-cache-manifest>'
                '<viewBody><Column><Text>Cached accounts</Text>'
                '<TextButton phx-click="quit_demo_mode">'
                '<Text>Quit demo mode</Text></TextButton>'
                '<Form method="post" action="/unsafe">'
                '<TextField name="memo" />'
                '</Form></Column></viewBody></flutter>',
          ],
        },
      ),
    );

    var oldChannel = server.lastChannel!;
    var initialRoute = view.router.pages.last.page.name;
    var observedRoutes = <String?>[];
    view.router.addListener(() {
      observedRoutes.add(view.router.pages.lastOrNull?.page.name);
    });
    await view.livePatch('/accounts');

    expect(
      observedRoutes,
      isNot(contains('loading;/accounts')),
      reason: 'a cached destination must not flash a loading route',
    );
    expect(view.router.pages.last.page.name, initialRoute);

    view.handleMessage(
      Message(event: PhoenixChannelEvent('phx_close')),
      sourceChannel: oldChannel,
    );
    await tester.pump();

    expect(find.text('Cached accounts'), findsOneWidget);
    expect(view.isCurrentRouteReady, isFalse);
    var cachedField = tester.widget<TextField>(find.byType(TextField));
    expect(cachedField.readOnly, isTrue);
    var requestCount = server.httpRequestsMade.length;
    await view.postForm({'memo': 'unsafe'}, url: '/unsafe');
    await view.execHrefClick('/users/log_out', method: 'DELETE');
    expect(server.httpRequestsMade, hasLength(requestCount));
    expect(
      view.sendEvent(
        ExecLiveEvent(type: 'click', name: 'unsafe', value: const {}),
      ),
      isFalse,
    );

    var newChannel = server.lastChannel!;
    await tester.tap(find.widgetWithText(TextButton, 'Quit demo mode'));
    expect(
      newChannel.actions.where((action) => action.eventName == 'event'),
      isEmpty,
      reason: 'cached actions wait for the authoritative channel render',
    );

    view.handleMessage(
      Message(
        event: PhoenixChannelEvent('phx_reply'),
        payload: {
          'response': {
            'rendered': {
              's': [
                '<flutter><viewBody><Text>Fresh accounts</Text></viewBody>'
                    '</flutter>',
              ],
            },
          },
        },
      ),
      sourceChannel: newChannel,
    );
    await tester.pumpAndSettle();

    expect(
      newChannel.actions,
      contains(
        const EventSent('event', {
          'type': 'phx-click',
          'event': 'quit_demo_mode',
          'value': <String, dynamic>{},
        }),
      ),
    );

    expect(find.text('Fresh accounts'), findsOneWidget);
    expect(find.text('Cached accounts'), findsNothing);
    expect(view.isCurrentRouteReady, isTrue);
  });
}
