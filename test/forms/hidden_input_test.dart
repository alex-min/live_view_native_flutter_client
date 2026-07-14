import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

var thanksPage = http.Response(
    """<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main=""><flutter>
            <csrf-token value="csrf"></csrf-token>
            <viewBody>
              <Text>done</Text>
            </viewBody>
          </flutter></div>
        """,
    200,
    headers: {'set-cookie': 'live_view=session2'});

main() async {
  testWidgets('includes hidden input value in form posts', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Form method="POST">
            <hidden name="user[email]" value="contact@example.org" />
            <TextField name="user[password]" initialValue="secret" />
            <ElevatedButton type="submit">Update</ElevatedButton>
          </Form>
        """
      ],
    }, onRequest: (request) {
      if (request.method == 'POST') {
        return thanksPage;
      }
      return null;
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    var formPost = server.httpRequestsMade.last;
    expect(formPost.method, 'POST');
    expect(
      Uri.decodeComponent(formPost.body),
      'user[email]=contact@example.org&user[password]=secret&_csrf_token=csrf',
    );
  });
}
