import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('DropdownButton with DropdownMenuItem renders', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <csrf-token value="token"></csrf-token>
            <div data-phx-session="session" data-phx-static="static">
              <AppBar>
                <title><Text>StartupKit</Text></title>
                <DropdownButton>
                  <icon><Icon name="menu" /></icon>
                  <DropdownMenuItem label="Sign in" value="sign_in" live-patch="/users/log_in" />
                  <DropdownMenuItem label="Sign up" value="sign_up" live-patch="/users/register" />
                </DropdownButton>
              </AppBar>
              <viewBody>
                <Text>Home page</Text>
              </viewBody>
            </div>
          </flutter>
          """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('StartupKit'), findsOneWidget);
    expect(find.byType(DropdownButton<String>), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String>));
    await tester.pumpAndSettle();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
