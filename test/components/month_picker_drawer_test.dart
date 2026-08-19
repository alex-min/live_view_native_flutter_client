import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_month_picker_drawer.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('month picker drawer pins year headers and renders month rows', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<flutter><viewBody><MonthPickerDrawer '
              'phx-click="close_month_picker">',
          '</MonthPickerDrawer></viewBody></flutter>',
        ],
        // Production renders the years through a server-side `for`, so the
        // drawer receives a dynamic comprehension rather than direct slivers.
        '0': {
          's': [
            '<MonthPickerYear year="',
            '"><ListTile><title><Text>',
            '</Text></title></ListTile></MonthPickerYear>',
          ],
          'd': [
            ['2026', 'August'],
            ['2025', 'December'],
          ],
        },
      },
    );
    await tester.runLiveView(view);
    await tester.pump();

    expect(find.byType(LiveMonthPickerDrawer), findsOneWidget);
    expect(find.byType(SliverPersistentHeader), findsNWidgets(2));
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('August'), findsOneWidget);
    expect(find.text('December'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({}, eventName: 'close_month_picker'),
    ]);
  });
}
