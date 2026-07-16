import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

var tosPage = http.Response(
  '''<div id="phx-id" data-phx-session="tos-session" data-phx-static="static" data-phx-main=""><flutter>
        <csrf-token value="csrf"></csrf-token>
        <viewBody>
          <Text>Terms of Service</Text>
        </viewBody>
      </flutter></div>
    ''',
  200,
  headers: const {'set-cookie': 'live_view=tos_session'},
);

void main() {
  testWidgets(
      'full render after navigation clears stale diff state from the previous page',
      (tester) async {
    var hasPosted = false;
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '''
          <Form method="POST" action="/users/log_in">
            <Text>Register</Text>
            <TextField name="user[email]" />
            <ElevatedButton type="submit">Sign up</ElevatedButton>
          </Form>
        '''
      ],
    }, onRequest: (request) {
      if (request.method == 'POST' && request.url.path == '/users/log_in') {
        hasPosted = true;
        return http.Response('', 302, headers: const {'location': '/'});
      }
      if (request.method == 'GET' && request.url.path == '/') {
        if (hasPosted) {
          return http.Response('', 302,
              headers: const {'location': '/users/accept-tos'});
        }
        return null;
      }
      if (request.method == 'GET' && request.url.path == '/users/accept-tos') {
        return tosPage;
      }
      return null;
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    // Simulate a validation diff arriving from the registration page before
    // the POST/redirect navigation completes. Without clearing the diff state,
    // the next full render would still see these old indexes.
    view.handleDiffMessage({
      '0': 'phx-trigger-action="true"',
      '1': 'errors="[]"',
    });
    await tester.pump();

    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    // The TOS page should render with its own content, not the stale diff.
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('phx-trigger-action="true"'), findsNothing);
    expect(find.text('errors="[]"'), findsNothing);
  });
}
