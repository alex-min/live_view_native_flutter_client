import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('root AppBar persists across navigation',
      (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <csrf-token value="token"></csrf-token>
            <div data-phx-session="session" data-phx-static="static">
              <AppBar>
                <title><Text>StartupKit</Text></title>
              </AppBar>
              <viewBody>
                <Text>Home page</Text>
                <TextButton live-patch="/second"><Text>Go to second</Text></TextButton>
              </viewBody>
            </div>
          </flutter>
        """
      ]
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('StartupKit'), findsOneWidget);
    expect(find.text('Home page'), findsOneWidget);

    // Navigate to second page with different title
    view.handleRenderedMessage({
      's': [
        """
          <flutter>
            <csrf-token value="token"></csrf-token>
            <div data-phx-session="session" data-phx-static="static">
              <AppBar>
                <title><Text>Second page</Text></title>
              </AppBar>
              <viewBody>
                <Text>Second page</Text>
              </viewBody>
            </div>
          </flutter>
        """
      ]
    });
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsNWidgets(2));
    expect(find.text('StartupKit'), findsNothing);
  });
}
