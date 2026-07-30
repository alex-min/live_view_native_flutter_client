import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('renders the trigger and the overlay child above the content', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
            <Column>
              <OverlayPortal>
                <child>
                  <ElevatedButton>Open</ElevatedButton>
                </child>
                <overlayChild>
                  <Card>
                    <ListTile phx-click="select" phx-value-code="USD">
                      <title><Text>USD (\$)</Text></title>
                    </ListTile>
                  </Card>
                </overlayChild>
              </OverlayPortal>
              <Text>Content below</Text>
            </Column>
          """,
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Content below'), findsOneWidget);
    expect(find.text(r'USD ($)'), findsOneWidget);

    // The overlay child is tappable even though it visually overflows its
    // parent: the event goes through.
    await tester.tap(find.text(r'USD ($)'));
    expect(
      server.lastChannelAction,
      liveEvents.phxClick({'code': 'USD'}, eventName: 'select'),
    );
  });

  testWidgets('an empty overlayChild renders nothing', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
            <OverlayPortal>
              <child>
                <ElevatedButton>Open</ElevatedButton>
              </child>
              <overlayChild>
              </overlayChild>
            </OverlayPortal>
          """,
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('Open'), findsOneWidget);
    expect(find.byType(Card), findsNothing);
  });
}
