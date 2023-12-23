import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:http/http.dart' as http;

import '../test_helpers.dart';

main() async {
  testWidgets('supports http form posts', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Form method="POST">
            <TextField name="user[email]" initialValue="contact@example.org" />
            <ElevatedButton type="submit">Sign-in</ElevatedButton>
          </Form>
        """
      ],
    }, onRequest: (request) {
      if (request.method == 'POST') {
        return http.Response(
            """<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Text>thanks for sign-in in</Text>
            </viewBody>
          </flutter></div>
        """, 200);
      }
      return null;
    });
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['thanks for sign-in in']);

    var formPost = server.httpRequestsMade.last;
    expect(formPost.headers['Cookie'], 'live_view=session');
    expect(formPost.headers['content-type'],
        'application/x-www-form-urlencoded; charset=utf-8');
    expect(formPost.method, 'POST');
    expect(formPost.body,
        'user%5Bemail%5D=contact%40example.org&_csrf_token=csrf');
    expect(formPost.url.toString(),
        'http://localhost:9999/?_lvn%5Bformat%5D=flutter');
  });
}
