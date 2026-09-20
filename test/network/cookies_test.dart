import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('cookies are stored and sent properly', (tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<Form method="POST">
            <TextField name="user[email]" initialValue="contact@example.org" />
            <ElevatedButton type="submit">Sign-in</ElevatedButton>
          </Form>
      """,
        ],
      },
      sharedPreferences: {'cookie': 'storedCookie'},
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(server.httpRequestsMade[0].headers['cookie'], 'storedCookie');
    expect(server.httpRequestsMade.last.headers['cookie'], 'live_view=session');
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cookie'), 'live_view=session');
  });

  testWidgets('recovers from malformed set-cookie headers', (tester) async {
    var clearedCookie =
        '_startup_kit_key=; path=/; expires=Thu, 01 Jan 1970 00:00:00 GMT; max-age=0; samesite=';

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<Form method="POST">
            <TextField name="user[email]" initialValue="contact@example.org" />
            <ElevatedButton type="submit">Sign-in</ElevatedButton>
          </Form>
      """,
        ],
      },
      onRequest: (request) {
        if (request.url.path == '/' && request.method == 'GET') {
          return http.Response(xmlCsrf, 200);
        }
        if (request.method == 'POST') {
          return http.Response(
            """<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
          <csrf-token value="csrf"></csrf-token>
          <viewBody><Text>done</Text></viewBody>
        </flutter></div>""",
            200,
            headers: {'set-cookie': clearedCookie},
          );
        }
        return null;
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    var formPost = server.httpRequestsMade.firstWhere(
      (r) => r.method == 'POST',
    );
    expect(formPost.headers['cookie'], isNull);

    // The expired _startup_kit_key cookie is dropped from the jar, leaving
    // nothing to send.
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cookie'), isNull);
  });

  testWidgets('forwards every stored cookie, not just the first one', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': ['<Text>hi</Text>'],
      },
      sharedPreferences: {'cookie': 'session=abc; support_visitor=xyz'},
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
      server.httpRequestsMade[0].headers['cookie'],
      'session=abc; support_visitor=xyz',
    );
  });

  testWidgets('accumulates cookies from several set-cookie headers', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': ['<Text>hi</Text>'],
      },
      onRequest: (request) {
        if (request.url.path == '/' && request.method == 'GET') {
          return http.Response(
            xmlCsrf,
            200,
            headers: {
              // Several set-cookie headers can be folded into one
              // comma-joined value, e.g. by proxies or HTTP/1.1 clients.
              'set-cookie':
                  'session=abc; path=/; httponly, support_visitor=xyz; path=/',
            },
          );
        }
        return null;
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cookie'), 'session=abc; support_visitor=xyz');
  });
}
