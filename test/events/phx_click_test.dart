import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('phx click on button', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        '<ElevatedButton phx-click="click_event"><Text>hello</Text></ElevatedButton>'
      ]
    });

    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    expect(server.lastChannelActions?.last, liveEvents.phxClick({}));
  });

  testWidgets('phx click on a text component', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': ['<Text phx-click="click_event">hello</Text>']
    });

    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveText));
    expect(server.lastChannelActions?.last, liveEvents.phxClick({}));
  });

  testWidgets('phx click on a bottom bar item', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
        <BottomNavigationBar>
          <BottomNavigationBarIcon phx-click="other_event" name="home" label="Page 1" />
          <BottomNavigationBarIcon phx-click="other_event" name="home" label="Page 2" />
          <BottomNavigationBarIcon phx-click="other_event" name="home" label="Page 3" />
          <BottomNavigationBarIcon phx-click="my_event" phx-value-something="hello" name="home" label="Page 4" />
        </BottomNavigationBar>
        """
      ]
    });

    await tester.runLiveView(view);

    await tester.pumpAndSettle();
    await tester.tap(find.text("Page 4"));
    expect(server.lastChannelActions?.last,
        liveEvents.phxClick({'something': 'hello'}, eventName: 'my_event'));
  });
}
