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
  testWidgets(
    'phx-trigger-action posts current form values after navigating between forms',
    (tester) async {
      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '''
          <flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Form action="/users/log_in" method="post">
                <TextField name="user[email]" />
                <TextField name="user[password]" />
                <TextButton live-patch="/users/register">Register</TextButton>
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

      // Type into the login form.
      var loginFields = find.byType(TextFormField);
      expect(loginFields, findsNWidgets(2));
      await tester.enterText(loginFields.at(0), 'login@example.org');
      await tester.pump();
      await tester.enterText(loginFields.at(1), 'loginPassword123!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      // Simulate live-patch navigation to the register page.
      view.currentUrl = '/users/register';
      view.connectionNotifier.wipeState();
      view.handleRenderedMessage({
        's': [
          '''
          <flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Form action="/users/log_in?_action=registered" method="post" phx-trigger-action="[[flutterState key=0]]">
                <TextField name="user[email]" />
                <TextField name="user[password]" />
                <TextField name="user[password_confirmation]" />
              </Form>
            </viewBody>
          </flutter>
        ''',
        ],
        '0': 'false',
      }, viewType: ViewType.deadView);
      await tester.pumpAndSettle();

      // Type into the register form.
      var registerFields = find.byType(TextFormField);
      expect(registerFields, findsNWidgets(3));
      await tester.enterText(registerFields.at(0), 'register@example.org');
      await tester.pump();
      await tester.enterText(registerFields.at(1), 'registerPassword123!');
      await tester.pump();
      await tester.enterText(registerFields.at(2), 'registerPassword123!');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      // Server triggers the form post.
      view.handleDiffMessage({'0': 'true'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 10));

      var posts = server.httpRequestsMade.where((r) => r.method == 'POST');
      expect(posts.length, 1);

      var body = posts.first.body;
      expect(body, contains('register%40example.org'));
      expect(body, contains('registerPassword123%21'));
      expect(body, isNot(contains('login%40example.org')));
    },
  );
}
