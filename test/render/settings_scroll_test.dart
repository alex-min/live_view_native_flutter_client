import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('scaffold body scrolls when implicit column overflows', (
    tester,
  ) async {
    tester.setScreenSize(const Size(1280, 720));
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <csrf-token value="token"></csrf-token>
            <div data-phx-session="session" data-phx-static="static">
              <Scaffold>
                <AppBar>
                  <title><Text>Settings</Text></title>
                </AppBar>
                <viewBody>
                  <Container height="300"><Text>A</Text></Container>
                </viewBody>
                <Container height="600"><Text>B</Text></Container>
              </Scaffold>
            </div>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
