import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

var tosPage = http.Response(
  """<div id="phx-id" data-phx-session="tos-session" data-phx-static="static" data-phx-main=""><flutter>
          <csrf-token value="csrf"></csrf-token>
          <viewBody>
            <Text>Terms of Service</Text>
            <Form method="POST" action="/users/accept-tos">
              <ElevatedButton type="submit">Accept</ElevatedButton>
            </Form>
          </viewBody>
        </flutter></div>
      """,
  200,
  headers: {'set-cookie': 'live_view=tos_session'},
);

void main() {
  testWidgets(
    'post-login redirect chain updates currentUrl and joins the right channel',
    (tester) async {
      var hasPosted = false;
      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
          <Form method="POST" action="/users/log_in">
            <TextField name="user[email]" initialValue="contact@example.org" />
            <ElevatedButton type="submit">Sign in</ElevatedButton>
          </Form>
        """,
          ],
        },
        onRequest: (request) {
          if (request.method == 'POST' && request.url.path == '/users/log_in') {
            hasPosted = true;
            return http.Response('', 302, headers: {'location': '/'});
          }
          if (request.method == 'GET' && request.url.path == '/') {
            if (hasPosted) {
              return http.Response(
                '',
                302,
                headers: {'location': '/users/accept-tos'},
              );
            }
            return null;
          }
          if (request.method == 'GET' &&
              request.url.path == '/users/accept-tos') {
            return tosPage;
          }
          return null;
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      await tester.tap(find.byType(LiveElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('Terms of Service'), findsOneWidget);
      expect(view.currentUrl, '/users/accept-tos');

      var liveSocket = server.socketsOpened.lastWhere(
        (s) => s.url.endsWith('/live/websocket'),
      );
      var channelParams =
          liveSocket.channelsAdded
              .firstWhere((c) => c.topic.startsWith('lv:'))
              .params;
      expect(
        channelParams?['url'],
        'http://localhost:9999/users/accept-tos',
        reason: 'The websocket channel should join the final redirect target',
      );
    },
  );
}
