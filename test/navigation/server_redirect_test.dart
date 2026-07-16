import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

var tosPage = http.Response(
    """<div id="phx-id" data-phx-session="tos-session" data-phx-static="static" data-phx-main=""><flutter>
          <csrf-token value="csrf"></csrf-token>
          <viewBody>
            <Text>Terms of Service</Text>
          </viewBody>
        </flutter></div>
      """,
    200,
    headers: {'set-cookie': 'live_view=tos_session'});

void main() {
  testWidgets('server redirect event navigates to the target URL',
      (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final view = LiveView();
    view.catchExceptions = false;

    final socket = FakeLiveSocket();
    final client = MockClient((request) async {
      socket.httpRequestsMade.add(request);
      if (request.method == 'GET' && request.url.path == '/users/accept-tos') {
        return tosPage;
      }
      return http.Response(xmlCsrf, 200,
          headers: {'set-cookie': 'live_view=session'});
    });

    view.liveSocket = socket;
    view.httpClient = client;

    await tester.runLiveView(view);
    await view.connect('http://localhost:9999/');

    view.handleMessage(Message(
      event: PhoenixChannelEvent.custom('redirect'),
      payload: {'to': '/users/accept-tos'},
    ));

    await tester.pumpAndSettle();

    final httpGets = socket.httpRequestsMade
        .where((r) => r.method == 'GET' && r.url.path == '/users/accept-tos')
        .toList();
    expect(
      httpGets,
      isNotEmpty,
      reason: 'Expected a dead-view GET to /users/accept-tos after redirect event',
    );

    expect(
      find.text('Terms of Service'),
      findsOneWidget,
      reason: 'The dead view of the redirect target should be rendered immediately',
    );
  });
}
