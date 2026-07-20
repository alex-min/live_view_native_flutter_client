import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

var _redirectResponse = http.Response(
  '''<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
    <csrf-token value="csrf"></csrf-token>
    <viewBody><Text>other page</Text></viewBody>
  </flutter></div>''',
  200,
);

main() async {
  testWidgets(
    'phx-trigger-action is only submitted once across offstage rebuilds',
    (tester) async {
      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '''
          <flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Form action="/users/log_in?_action=registered" method="post" phx-trigger-action="true">
                <TextField name="user[email]" initialValue="contact@example.org" />
              </Form>
            </viewBody>
          </flutter>
        ''',
          ],
        },
        onRequest: (request) {
          if (request.method == 'POST') {
            return _redirectResponse;
          }
          return null;
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      expect(
        server.httpRequestsMade.where((r) => r.method == 'POST').length,
        1,
      );

      // Simulate navigation to another page. The original form is kept offstage
      // and will be rebuilt; it must not post again.
      view.currentUrl = '/other';
      view.handleRenderedMessage({
        's': [
          '''<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
          <csrf-token value="csrf"></csrf-token>
          <viewBody><Text>other page</Text></viewBody>
        </flutter></div>''',
        ],
      });
      await tester.pumpAndSettle();

      expect(
        server.httpRequestsMade.where((r) => r.method == 'POST').length,
        1,
      );
    },
  );
}
