import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('Stack clips by default and supports clipBehavior none', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <csrf-token value="token"></csrf-token>
            <div data-phx-session="session" data-phx-static="static">
              <viewBody>
                <Column>
                  <Stack id="clipped"><Text>clipped</Text></Stack>
                  <Stack id="unclipped" clipBehavior="none"><Text>unclipped</Text></Stack>
                </Column>
              </viewBody>
            </div>
          </flutter>
          """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final stacks = tester.widgetList<Stack>(find.byType(Stack)).toList();
    expect(stacks.length, greaterThanOrEqualTo(2));
    expect(
      stacks.firstWhere((s) => s.clipBehavior == Clip.hardEdge),
      isNotNull,
      reason: 'A Stack without clipBehavior should clip',
    );
    expect(
      stacks.firstWhere((s) => s.clipBehavior == Clip.none),
      isNotNull,
      reason: 'clipBehavior="none" should disable clipping',
    );
  });
}
