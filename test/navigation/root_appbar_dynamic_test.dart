import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('root AppBar extracted from dynamic component',
      (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <csrf-token value="token"></csrf-token>
          <div id="phx-1" data-phx-session="session" data-phx-static="static" data-phx-main>
            <flutter>
        """,
        """
              <viewBody>
                <Text>Home page</Text>
              </viewBody>
            </flutter>
          </div>
        """
      ],
      '0': {
        's': [
          """
            <AppBar backgroundColor="@theme.colorScheme.primary" foregroundColor="@theme.colorScheme.onPrimary" elevation="0">
              <title>
                <Text style="color: @theme.colorScheme.onPrimary">StartupKit</Text>
              </title>
              <Row>
                <TextButton live-patch="/users/log_in"><Text style="color: @theme.colorScheme.onPrimary">Sign in</Text></TextButton>
              </Row>
            </AppBar>
          """
        ]
      }
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('StartupKit'), findsOneWidget);
    expect(find.text('Home page'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
