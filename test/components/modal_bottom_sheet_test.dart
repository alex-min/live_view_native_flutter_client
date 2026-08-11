import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('presents a dismissible bottom sheet and sends one close event', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<flutter><viewBody>'
              '<modal presentation="bottomSheet" close-event="closePicker">'
              '<title><AppBar><title>Choose a month</title></AppBar></title>'
              '<content><Text>Month choices</Text></content>'
              '</modal>'
              '<Text>Report</Text>'
              '</viewBody></flutter>',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('Choose a month'), findsOneWidget);
    expect(find.text('Month choices'), findsOneWidget);
    expect(find.byType(BottomSheet), findsOneWidget);

    Navigator.of(
      tester.element(find.text('Month choices')),
      rootNavigator: true,
    ).pop();
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.event('closePicker'),
    ]);
    expect(find.text('Month choices'), findsNothing);
  });
}
