import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_button.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

var loggedOutPage = http.Response(
    """<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Text>logged out</Text>
            </viewBody>
          </flutter></div>
        """,
    200,
    headers: {'set-cookie': 'live_view=cleared'});

main() async {
  testWidgets('supports delete navigation via phx-href', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <TextButton phx-href="/users/log_out" method="delete">Log out</TextButton>
        """
      ],
    }, onRequest: (request) {
      if (request.method == 'DELETE') {
        return http.Response('', 302, headers: {'location': '/'});
      }
      if (request.method == 'GET' && request.url.path == '/') {
        return loggedOutPage;
      }
      return null;
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveTextButton));
    await tester.pumpAndSettle();
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    await tester.pumpAndSettle();

    expect(find.allTexts(), contains('logged out'));

    var deleteRequest = server.httpRequestsMade.firstWhere(
      (request) => request.method == 'DELETE',
    );
    expect(deleteRequest.url.toString(),
        'http://localhost:9999/users/log_out?_format=flutter');
    expect(deleteRequest.headers['x-csrf-token'], 'csrf');
  });
}
