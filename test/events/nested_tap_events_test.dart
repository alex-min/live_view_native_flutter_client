import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  testWidgets('child buttons stay tappable inside a live-patch container', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container live-patch="/accounts" padding="20">
            <Row>
              <Text>Account row</Text>
              <DropdownButton>
                <icon><Icon name="more_vert" /></icon>
                <underline><SizedBox height="0.0" /></underline>
                <DropdownMenuItem label="Edit" value="edit" live-patch="/accounts/1/edit" />
              </DropdownButton>
            </Row>
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert), warnIfMissed: false);
    await tester.pumpAndSettle();

    // The dropdown opened instead of the row's live-patch firing.
    expect(
      find.text('Edit').hitTestable(),
      findsWidgets,
      reason: 'Tapping the overflow icon should open its menu, not navigate',
    );
    expect(
      server.lastChannelAction,
      isNot(liveEvents.phxClick({}, eventName: 'live_patch')),
    );
  });

  testWidgets('tapping non-interactive row content still fires the tap event', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Container phx-click="row_click" padding="20">
            <Text>Account row</Text>
          </Container>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Account row'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(
      server.lastChannelAction,
      liveEvents.phxClick({}, eventName: 'row_click'),
    );
  });
}
