import 'package:flutter/material.dart';
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
  testWidgets('phx-trigger-action posts current form values after a diff', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Form action="/users/log_in?_action=registered" method="post" phx-trigger-action="[[flutterState key=0]]">
                <TextField name="user[email]" />
                <TextField name="user[password]" />
              </Form>
            </viewBody>
          </flutter>
        ''',
        ],
        '0': 'false',
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

    var fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(2));

    await tester.enterText(fields.at(0), 'user@example.org');
    await tester.pump();
    await tester.enterText(fields.at(1), 'SuperSecret123!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    view.handleDiffMessage({'0': 'true'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    var posts = server.httpRequestsMade.where((r) => r.method == 'POST');
    expect(posts.length, 1);

    var body = posts.first.body;
    expect(body, contains('user%5Bemail%5D'));
    expect(body, contains('user%40example.org'));
    expect(body, contains('user%5Bpassword%5D'));
    expect(body, contains('SuperSecret123%21'));
  });
}
