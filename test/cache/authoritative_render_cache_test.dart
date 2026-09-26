import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_namespace.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_snapshot.dart';
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

  test(
    'prefetches authenticated HTTP presentation without join secrets',
    () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(store: store);
      var prefetchBody =
          '<meta name="csrf-token" content="prefetch-secret">'
          '<div id="prefetch-root" data-phx-main '
          'data-phx-session="signed" data-phx-static="static">'
          '<flutter><live-cache-manifest version="finance-v1" scope="user" '
          'identity="opaque-user" strategy="stale-while-revalidate">'
          '<live-cache-route href="/accounts" max-age="300" />'
          '<live-cache-route href="/dashboard" max-age="300" priority="high" />'
          '</live-cache-manifest><viewBody><Text>Dashboard</Text></viewBody>'
          '</flutter></div>';
      var (view, server) = await connect(
        LiveView(cacheCoordinator: coordinator),
        url: 'http://localhost:9999/accounts',
        onRequest:
            (request) =>
                request.url.path == '/dashboard'
                    ? http.Response(prefetchBody, 200)
                    : null,
      );
      var channel = server.lastChannel!;
      var renderedWithDashboard = {
        's': [
          '<flutter><live-cache-manifest version="finance-v1" scope="user" '
              'identity="opaque-user" strategy="stale-while-revalidate">'
              '<live-cache-route href="/accounts" max-age="300" />'
              '<live-cache-route href="/dashboard" max-age="300" priority="high" />'
              '</live-cache-manifest><Text>Accounts</Text></flutter>',
        ],
      };

      view.handleMessage(
        Message(
          event: PhoenixChannelEvent('phx_reply'),
          payload: {
            'response': {'rendered': renderedWithDashboard},
          },
        ),
        sourceChannel: channel,
      );
      await Future<void>.delayed(Duration.zero);
      expect(await view.cachePrefetchComplete, 1);

      var snapshot = await store.readSnapshot(
        coordinator.namespace!,
        Uri.parse('/dashboard'),
      );
      expect(snapshot, isNotNull);
      var markup = (snapshot!.rendered['s'] as List).single as String;
      expect(markup, contains('Dashboard'));
      expect(markup, isNot(contains('prefetch-secret')));
      expect(markup, isNot(contains('data-phx-session')));
      expect(
        server.httpRequestsMade
            .where((request) => request.url.path == '/dashboard')
            .single
            .headers['cookie'],
        'live_view=session',
      );
    },
  );

  for (var responseKind in [
    'cross origin',
    'missing policy',
    'anonymous',
    'different identity',
  ]) {
    test('prefetch handles $responseKind explicitly', () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(store: store);
      var (view, server) = await connect(
        LiveView(cacheCoordinator: coordinator),
        url: 'http://localhost:9999/accounts',
        onRequest:
            (request) =>
                request.url.path == '/dashboard'
                    ? responseKind == 'cross origin'
                        ? http.Response(
                          '',
                          302,
                          headers: {'location': 'https://other.test/'},
                        )
                        : http.Response(
                          responseKind == 'different identity'
                              ? '<div data-phx-main><flutter><live-cache-manifest version="finance-v1" scope="user" identity="other-user" strategy="stale-while-revalidate"></live-cache-manifest></flutter></div>'
                              : '<div data-phx-main><flutter><Text>Uncached</Text></flutter></div>',
                          200,
                          headers: {
                            if (responseKind == 'anonymous')
                              'x-live-view-session': 'anonymous',
                          },
                        )
                    : null,
      );
      var channel = server.lastChannel!;
      view.handleMessage(
        Message(
          event: PhoenixChannelEvent('phx_reply'),
          payload: {
            'response': {
              'rendered': {
                's': [
                  '<flutter><live-cache-manifest version="finance-v1" '
                      'scope="user" identity="opaque-user" '
                      'strategy="stale-while-revalidate">'
                      '<live-cache-route href="/accounts" max-age="300" />'
                      '<live-cache-route href="/dashboard" max-age="300" />'
                      '</live-cache-manifest><Text>Accounts</Text></flutter>',
                ],
              },
            },
          },
        ),
        sourceChannel: channel,
      );
      await Future<void>.delayed(Duration.zero);
      await view.cachePrefetchComplete;

      expect(
        coordinator.namespace,
        responseKind == 'missing policy' ? isNotNull : isNull,
      );
      if (responseKind == 'missing policy') {
        expect(
          await coordinator.loadForNavigation(Uri.parse('/accounts')),
          isNotNull,
        );
        expect(
          await coordinator.loadForNavigation(Uri.parse('/dashboard')),
          isNull,
        );
      }
      expect(
        server.httpRequestsMade.any(
          (request) => request.url.host == 'other.test',
        ),
        isFalse,
      );
    });
  }

  for (var mode in [
    'live',
    'dead',
    'cached replacement',
    'GET reset',
    'POST reset',
    'DELETE reset',
    'expired session',
  ]) {
    test('cache history handles $mode independently of missing policy', () async {
      var store = MemoryLiveViewCacheStore();
      var coordinator = LiveViewCacheCoordinator(store: store);
      var (view, _) = await connect(
        LiveView(cacheCoordinator: coordinator),
        url: 'http://localhost:9999/accounts',
        onRequest:
            (request) =>
                request.url.path == '/session-boundary'
                    ? http.Response(
                      xmlCsrf,
                      200,
                      headers: {
                        if (mode == 'expired session')
                          'x-live-view-session': 'anonymous'
                        else
                          'x-live-view-session-reset': 'true',
                      },
                    )
                    : null,
      );
      const namespace = LiveCacheNamespace(
        origin: 'http://localhost:9999',
        scope: LiveCacheScope.user,
        identity: 'opaque-user',
        manifestVersion: 'finance-v1',
        rendererVersion: LiveView.cacheRendererVersion,
        locale: 'en',
        theme: 'cosmic/light',
      );
      var manifest = LiveCacheManifest(
        version: 'finance-v1',
        scope: LiveCacheScope.user,
        identity: 'opaque-user',
        strategy: LiveCacheStrategy.staleWhileRevalidate,
        routes: [
          LiveCacheRoute(
            href: Uri.parse('/accounts'),
            maxAge: const Duration(minutes: 5),
            priority: LiveCachePriority.normal,
          ),
        ],
      );
      await coordinator.acceptManifest(
        namespace: namespace,
        manifest: manifest,
      );
      await store.writeSnapshot(
        LiveCacheSnapshot(
          namespace: namespace,
          route: Uri.parse('/accounts'),
          storedAt: DateTime.now(),
          rendered: const {
            's': ['accounts'],
          },
        ),
      );
      view.router.replacePages(
        url: '/old-authenticated-page',
        widget: const [Text('Old page')],
        rootState: null,
      );

      var resets = mode.endsWith('reset') || mode == 'expired session';
      if (mode == 'POST reset') {
        await view.deadViewPostQuery('/session-boundary', {});
      } else if (mode == 'DELETE reset') {
        await view.deadViewDeleteQuery('/session-boundary');
      } else if (resets) {
        await view.deadViewGetQuery('/session-boundary');
      }
      await view.handleRenderedMessage(
        const {
          's': [
            '<flutter><viewBody><Text>Uncached page</Text></viewBody></flutter>',
          ],
        },
        viewType:
            mode == 'cached replacement'
                ? ViewType.cached
                : mode == 'live'
                ? ViewType.liveView
                : ViewType.deadView,
        replacePage: mode == 'cached replacement',
      );
      await Future<void>.delayed(Duration.zero);

      expect(coordinator.namespace, resets ? isNull : namespace);
      expect(
        await store.readSnapshot(namespace, Uri.parse('/accounts')),
        resets ? isNull : isNotNull,
      );
      expect(
        view.router.pages,
        hasLength(resets || mode == 'cached replacement' ? 1 : 2),
      );
      expect(view.router.pages.last.page.name, '/accounts');
    });
  }
}
