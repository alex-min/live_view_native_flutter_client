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
      'offstage form does not post when a diff targets the current page',
      (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '''
          <flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Form action="/users/log_in?_action=password_updated" method="post" phx-trigger-action="[[flutterState key=0]]">
                <Text>settings form</Text>
              </Form>
            </viewBody>
          </flutter>
        '''
      ],
      '0': 'false'
    }, onRequest: (request) {
      if (request.method == 'POST') {
        return _redirectResponse;
      }
      return null;
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    // The settings form is rendered with phx-trigger-action="false" and never
    // posts, so its last known value is "false".
    expect(server.httpRequestsMade.where((r) => r.method == 'POST').length, 0);

    // Simulate logout / navigation to the registration page.
    view.currentUrl = '/users/register';
    view.handleRenderedMessage({
      's': [
        '''<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
          <csrf-token value="csrf"></csrf-token>
          <viewBody>
            <Form action="/users/log_in?_action=registered" method="post" phx-trigger-action="[[flutterState key=0]]">
              <Text>register form</Text>
            </Form>
          </viewBody>
        </flutter></div>'''
      ],
      '0': 'false'
    }, viewType: ViewType.deadView);
    await tester.pumpAndSettle();

    // A diff from the registration page updates the shared trigger_submit key.
    // Top-level pages share nestedState=[], so the offstage settings form sees
    // the same diff. It must not post to its own action.
    view.handleDiffMessage({'0': 'true'});
    await tester.pump();
    await tester.pump();

    var posts = server.httpRequestsMade.where((r) => r.method == 'POST');
    expect(posts.length, 1);
    expect(posts.first.url.toString(), contains('_action=registered'));
    expect(
      posts.where((r) => r.url.toString().contains('password_updated')),
      isEmpty,
    );
  });
}
