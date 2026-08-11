import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_month_picker_drawer.dart';

import '../test_helpers.dart';

void main() {
  Future<dynamic> renderDrawer(WidgetTester tester, String xml) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': ['<flutter><viewBody>$xml</viewBody></flutter>'],
      },
    );
    await tester.runLiveView(view);
    await tester.pump();
    return server;
  }

  testWidgets('month picker drawer pins year headers and renders month rows', (
    tester,
  ) async {
    final server = await renderDrawer(tester, '''
      <MonthPickerDrawer phx-click="close_month_picker">
        <MonthPickerYear year="2026">
          <ListTile><title><Text>August</Text></title></ListTile>
          <ListTile><title><Text>July</Text></title></ListTile>
        </MonthPickerYear>
        <MonthPickerYear year="2025">
          <ListTile><title><Text>December</Text></title></ListTile>
        </MonthPickerYear>
      </MonthPickerDrawer>
      ''');

    expect(find.byType(LiveMonthPickerDrawer), findsOneWidget);
    expect(find.byType(SliverPersistentHeader), findsNWidgets(2));
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('August'), findsOneWidget);
    expect(find.text('July'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({}, eventName: 'close_month_picker'),
    ]);
  });
}
