import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
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
          <BottomNavigationBarItem phx-click="other_event" icon="home" label="Page 1" />
          <BottomNavigationBarItem phx-click="other_event" icon="home" label="Page 2" />
          <BottomNavigationBarItem phx-click="other_event" icon="home" label="Page 3" />
          <BottomNavigationBarItem phx-click="my_event" phx-value-something="hello" icon="home" label="Page 4" />
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

  testWidgets('phx click on a text component', (tester) async {
    await loadAppFonts();
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """<Text
              phx-click="click_event"
              data-confirm="This action cannot be undone!"
              data-confirm-title="Are you sure?"
              data-confirm-confirm="Confirm"
              data-confirm-cancel="Cancel"
          >hello</Text>"""
      ]
    });
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LiveText));
    await tester.pumpAndSettle();
    expect(server.lastChannelActions?.last, isNot(liveEvents.phxClick({})));

    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(server.lastChannelActions?.last, isNot(liveEvents.phxClick({})));

    await tester.tap(find.byType(LiveText));
    await tester.pumpAndSettle();
    expect(server.lastChannelActions?.last, isNot(liveEvents.phxClick({})));

    await tester.tap(find.text("Confirm"));
    await tester.pumpAndSettle();
    expect(server.lastChannelActions?.last, liveEvents.phxClick({}));
  });
}
