import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

/// A fake push whose future completes with a Phoenix `stale` join error. This
/// mirrors what Phoenix LiveView returns when the session token no longer
/// matches the current cookie session.
class _StalePush extends FakePushMessage {
  _StalePush(super.channel);

  @override
  Future<PushResponse> get future async =>
      const PushResponse(status: 'error', response: {'reason': 'stale'});
}

/// A fake channel that errors on every join with a `stale` response.
class StaleFakeChannel extends FakePhoenixChannel {
  StaleFakeChannel(super.socket, super.topic, super.params);

  @override
  Push join([Duration? newTimeout]) {
    actions.add(const EventSent('join', null));
    currentState = PhoenixChannelState.errored;
    return _StalePush(this);
  }
}

/// A fake Phoenix socket that creates [StaleFakeChannel] channels.
class StaleFakePhoenixSocket extends FakePhoenixSocket {
  StaleFakePhoenixSocket(super.url, super.socketOptions);

  @override
  PhoenixChannel addChannel({
    required String topic,
    Map<String, dynamic>? parameters,
    Duration? timeout,
  }) {
    actions.add(EventSent('addChannel', parameters));
    var channel = StaleFakeChannel(this, topic, parameters);
    channelsAdded.add(channel);
    return channel;
  }
}

/// A fake Live socket that creates [StaleFakePhoenixSocket] sockets.
class StaleFakeLiveSocket extends FakeLiveSocket {
  @override
  PhoenixSocket create({
    required String url,
    required Map<String, dynamic> params,
    required Map<String, String> headers,
  }) {
    var socket = StaleFakePhoenixSocket(url, PhoenixSocketOptions());
    socketsOpened.add(socket);
    return socket;
  }
}

var tosPage = http.Response(
  '''<div id="phx-id" data-phx-session="tos-session" data-phx-static="static" data-phx-main=""><flutter>
        <csrf-token value="csrf"></csrf-token>
        <viewBody>
          <Text>Terms of Service</Text>
          <Form method="POST" action="/users/accept-tos">
            <ElevatedButton type="submit">Accept</ElevatedButton>
          </Form>
        </viewBody>
      </flutter></div>
    ''',
  200,
  headers: const {'set-cookie': 'live_view=tos_session'},
);

void main() {
  testWidgets(
    'stale websocket join after dead-view navigation does not reload in a loop',
    (tester) async {
      TestWidgetsFlutterBinding.ensureInitialized();
      SharedPreferences.setMockInitialValues({});

      final view = LiveView();
      view.catchExceptions = false;

      final socket = StaleFakeLiveSocket();
      final client = MockClient((request) async {
        socket.httpRequestsMade.add(request);
        if (request.method == 'GET' &&
            request.url.path == '/users/accept-tos') {
          return tosPage;
        }
        return http.Response(
          xmlCsrf,
          200,
          headers: const {'set-cookie': 'live_view=session'},
        );
      });

      view.liveSocket = socket;
      view.httpClient = client;

      await tester.runLiveView(view);
      await view.connect('http://localhost:9999/');

      // Simulate the post-sign-up state: the socket has been disconnected after
      // the HTTP POST and the client now loads the TOS page via dead view.
      await view.disconnect();
      await view.execHrefClick('/users/accept-tos');
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);

      // The TOS page should have been fetched exactly once. Before the fix the
      // client would fall back to execHrefClick('/users/accept-tos') again after
      // the stale join, causing an infinite loop of GETs.
      final tosGets =
          socket.httpRequestsMade
              .where(
                (r) => r.method == 'GET' && r.url.path == '/users/accept-tos',
              )
              .toList();
      expect(
        tosGets,
        hasLength(1),
        reason: 'A stale join should not reload the same dead view in a loop',
      );

      // A fresh dead-view navigation must join with _mounts: 0. Using a global
      // counter here caused Phoenix to reject the join as stale and triggered
      // the loop in the first place.
      final tosChannel = socket.liveSocket?.channelsAdded.lastWhere(
        (c) => c.topic.startsWith('lv:'),
        orElse: () => throw StateError('No lv: channel found'),
      );
      expect(
        tosChannel?.params?['params']?['_mounts'],
        '0',
        reason: 'A new LiveView join must start with _mounts: 0',
      );
    },
  );
}
