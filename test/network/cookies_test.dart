import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('cookies are stored and sent properly', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """<Form method="POST">
            <TextField name="user[email]" initialValue="contact@example.org" />
            <ElevatedButton type="submit">Sign-in</ElevatedButton>
          </Form>
      """
      ],
    }, sharedPreferences: {
      'cookie': 'storedCookie'
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(server.httpRequestsMade[0].headers['cookie'], 'storedCookie');
    expect(server.httpRequestsMade.last.headers['cookie'], 'live_view=session');
    var prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('cookie'), 'live_view=session');
  });
}
