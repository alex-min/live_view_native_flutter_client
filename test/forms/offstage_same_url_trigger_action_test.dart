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
  testWidgets('offstage form with the same url does not post stale values', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      url: 'http://localhost:9999/users/register',
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

    // Fill the first register form.
    var firstFields = find.byType(TextFormField);
    expect(firstFields, findsNWidgets(2));
    await tester.enterText(firstFields.at(0), 'first@example.org');
    await tester.pump();
    await tester.enterText(firstFields.at(1), 'firstPassword123!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    // Simulate navigating to login and back to /users/register,
    // leaving the first form offstage with an intermediate page in between.
    view.currentUrl = '/users/log_in';
    view.connectionNotifier.wipeState();
    view.handleRenderedMessage({
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
    }, viewType: ViewType.deadView);
    await tester.pumpAndSettle();

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
              </Form>
            </viewBody>
          </flutter>
        ''',
      ],
      '0': 'false',
    }, viewType: ViewType.deadView);
    await tester.pumpAndSettle();

    // Fill the second (current) register form with different values.
    var secondFields = find.byType(TextFormField);
    expect(secondFields, findsNWidgets(2));
    await tester.enterText(secondFields.at(0), 'second@example.org');
    await tester.pump();
    await tester.enterText(secondFields.at(1), 'secondPassword123!');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    // Server triggers the form post.
    view.handleDiffMessage({'0': 'true'});
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 10));

    var posts = server.httpRequestsMade.where((r) => r.method == 'POST');
    expect(posts.length, 1);

    var body = posts.first.body;
    expect(body, contains('second%40example.org'));
    expect(body, contains('secondPassword123%21'));
    expect(body, isNot(contains('first%40example.org')));
  });
}
