import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_helpers.dart';

/// A fake push whose future completes with a Phoenix join error. This mirrors
/// what Phoenix LiveView returns when a `live_patch` target lives in a
/// different `live_session`.
class _ErrorPush extends FakePushMessage {
  _ErrorPush(super.channel);

  @override
  Future<PushResponse> get future async =>
      const PushResponse(status: 'error', response: {'reason': 'unauthorized'});
}

/// A fake channel that errors on join whenever the join params contain a
/// `redirect` key.
class CrossSessionFakeChannel extends FakePhoenixChannel {
  CrossSessionFakeChannel(super.socket, super.topic, super.params);

  @override
  Push join([Duration? newTimeout]) {
    if (params?.containsKey('redirect') == true) {
      actions.add(const EventSent('join', null));
      currentState = PhoenixChannelState.errored;
      return _ErrorPush(this);
    }
    return super.join(newTimeout);
  }

  @override
  Push push(
    String eventName,
    Map<String, dynamic> payload, [
    Duration? newTimeout,
  ]) {
    var push = super.push(eventName, payload, newTimeout);
    if (eventName == 'phx_leave') {
      // Simulate the server closing the channel after phx_leave.
      Future.microtask(() {
        trigger(
          Message(
            event: PhoenixChannelEvent.close,
            payload: const <String, String>{},
          ),
        );
      });
    }
    return push;
  }
}

/// A fake Phoenix socket that creates [CrossSessionFakeChannel] channels.
class CrossSessionFakePhoenixSocket extends FakePhoenixSocket {
  CrossSessionFakePhoenixSocket(super.url, super.socketOptions);

  @override
  PhoenixChannel addChannel({
    required String topic,
    Map<String, dynamic>? parameters,
    Duration? timeout,
  }) {
    actions.add(EventSent('addChannel', parameters));
    var channel = CrossSessionFakeChannel(this, topic, parameters);
    channelsAdded.add(channel);
    return channel;
  }
}

/// A fake Live socket that creates [CrossSessionFakePhoenixSocket] sockets.
class CrossSessionFakeLiveSocket extends FakeLiveSocket {
  @override
  PhoenixSocket create({
    required String url,
    required Map<String, dynamic> params,
    required Map<String, String> headers,
  }) {
    var socket = CrossSessionFakePhoenixSocket(url, PhoenixSocketOptions());
    socketsOpened.add(socket);
    return socket;
  }
}

void main() {
  testWidgets('live-patch across live_sessions reconnects to target url', (
    tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final view = LiveView();
    view.catchExceptions = false;

    final socket = CrossSessionFakeLiveSocket();
    final client = MockClient((request) async {
      socket.httpRequestsMade.add(request);
      return http.Response(
        xmlCsrf,
        200,
        headers: {'set-cookie': 'live_view=session'},
      );
    });

    view.liveSocket = socket;
    view.httpClient = client;

    await tester.runLiveView(view);
    await view.connect('http://localhost:9999/');

    view.handleRenderedMessage({
      's': [
        '<AppBar><title><Text>StartupKit</Text></title>'
            '<TextButton live-patch="/users/log_in"><Text>Sign in</Text></TextButton>'
            '</AppBar>'
            '<viewBody><Center><Column><Text>Welcome</Text></Column></Center></viewBody>',
      ],
    });
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);

    await tester.tap(find.text('Sign in'), warnIfMissed: false);
    await tester.pump();

    // The client should have tried the redirect join, seen the error, and
    // reconnected to the target URL via a fresh HTTP GET.
    final navigationLogs = socket.liveSocket?.navigationLogs ?? [];
    expect(
      navigationLogs.any(
        (log) => log['redirect']?.endsWith('/users/log_in') ?? false,
      ),
      isTrue,
      reason: 'Expected a redirect join attempt to /users/log_in',
    );

    final httpGets =
        socket.httpRequestsMade
            .where((r) => r.method == 'GET' && r.url.path == '/users/log_in')
            .toList();
    expect(
      httpGets,
      isNotEmpty,
      reason:
          'Expected a dead-view GET to /users/log_in after cross-session redirect failed',
    );
  });
}
