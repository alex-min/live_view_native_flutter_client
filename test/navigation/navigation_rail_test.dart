import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testGoldens(
      'navigation rail looks okay', (tester) => tester.checkScreenshot("""
        <flutter>
          <NavigationRail labelType="all" selectedIndex="1" indicatorColor="blue-500" useIndicator="true">
            <NavigationRailDestination icon="home" label="Home" />
            <NavigationRailDestination icon="wallet" label="Wallet" />
            <NavigationRailDestination icon="apps" label="Photos" />
            <NavigationRailDestination icon="window" label="Albums" />
          </NavigationRail>
          <viewBody>my view</viewBody>
        </flutter>
        """, "navigation_rail_test.png"));

  testWidgets('phx-click works', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
        <NavigationRail labelType="all" phx-click="parent_event">
          <NavigationRailDestination icon="home" label="Home" />
          <NavigationRailDestination phx-click="child_event" icon="wallet" label="Wallets" />
          <NavigationRailDestination icon="apps" label="Photos" />
          <NavigationRailDestination icon="window" label="Albums" />
        </NavigationRail>"""
      ]
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Wallets'));
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({}, eventName: 'parent_event'),
      liveEvents.phxClick({}, eventName: 'child_event'),
      liveEvents.phxClick({}, eventName: 'parent_event'),
    ]);

    expect(find.firstOf<NavigationRail>().selectedIndex, 1);
  });

  testWidgets('initialValue cannot be changed', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
        <NavigationRail labelType="all" phx-click="parent_event"
        """,
        """ >
          <NavigationRailDestination icon="home" label="Home" />
          <NavigationRailDestination phx-click="child_event" icon="wallet" label="Wallets" />
          <NavigationRailDestination icon="apps" label="Photos" />
          <NavigationRailDestination icon="window" label="Albums" />
        </NavigationRail>""",
      ],
      '0': 'initialValue="1"'
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstOf<NavigationRail>().selectedIndex, 1);

    view.handleDiffMessage({'0': 'initialValue="2"'});
    await tester.pumpAndSettle();

    expect(find.firstOf<NavigationRail>().selectedIndex, 1);
  });
}
