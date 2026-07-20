import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('settings page scrolls when flash message is present', (
    tester,
  ) async {
    tester.setScreenSize(const Size(1280, 720));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <AppBar>
              <title><Text>Settings</Text></title>
            </AppBar>
            <viewBody>
              <SingleChildScrollView padding="24.0">
                <Column crossAxisAlignment="start">
                  <ScaffoldMessage kind="info">
                    <Text>A link to confirm your email change has been sent to the new address.</Text>
                  </ScaffoldMessage>
                  <Container height="900"><Text>Scrollable content</Text></Container>
                </Column>
              </SingleChildScrollView>
            </viewBody>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsOneWidget);
    expect(find.text('Scrollable content'), findsOneWidget);
    expect(
      find.text(
        'A link to confirm your email change has been sent to the new address.',
      ),
      findsOneWidget,
    );

    // Let the scaffold message timer fire so it is cleaned up before the test ends.
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });
}
