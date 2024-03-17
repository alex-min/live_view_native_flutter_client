import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

bool? checkValue() =>
    (find.byType(Checkbox).evaluate().first.widget as Checkbox).value;

main() async {
  testWidgets('normal looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <FloatingActionButton shape="CircleBorder"><Icon name="home" /></FloatingActionButton>
            <viewBody>hello world</viewBody>
          </flutter>
        """, 'foating_action_button_test.png'));

  testWidgets('extended looks okay', (tester) => tester.checkScreenshot("""
          <flutter>
            <FloatingActionButton isExtended="true"><Text>hello</Text><Icon name="home" /></FloatingActionButton>
            <viewBody>hello world</viewBody>
          </flutter>
        """, 'foating_action_button_extended_test.png'));

  testWidgets('phx click works', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <FloatingActionButton phx-click="server_event" shape="CircleBorder">hello</FloatingActionButton>
            <viewBody>my view</viewBody>
          </flutter>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'));
    await tester.pumpAndSettle();

    expect(server.lastChannelAction,
        liveEvents.phxClick({}, eventName: 'server_event'));
  });
}
