import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  for (var mode in ['push', 'replace']) {
    testWidgets(
      'bottom nav bar and FAB stay mounted through a $mode live-patch',
      (tester) async {
        tester.setScreenSize(const Size(400, 800));

        var (view, _) = await connect(
          LiveView(),
          rendered: {
            's': [_page('First page', '/second-page')],
          },
        );

        await tester.runLiveView(view);
        await tester.pumpAndSettle();

        final fabState = tester.state(find.byType(LiveFloatingActionButton));
        final barState = tester.state(find.byType(LiveBottomNavigationBar));

        // Trigger the navigation; the loading page is pushed and a frame is
        // rendered before the destination content arrives, like a real
        // network roundtrip.
        unawaited(view.livePatch('/second-page', replace: mode == 'replace'));
        await tester.pump();

        expect(
          find.byType(LiveFloatingActionButton),
          findsOneWidget,
          reason: 'the FAB must not disappear while the $mode patch loads',
        );
        expect(
          find.byType(LiveBottomNavigationBar),
          findsOneWidget,
          reason:
              'the bottom bar must not disappear while the $mode patch loads',
        );
        expect(
          tester.state(find.byType(LiveFloatingActionButton)),
          same(fabState),
          reason: 'the loading frame must keep the same FAB state',
        );
        expect(
          tester.state(find.byType(LiveBottomNavigationBar)),
          same(barState),
          reason: 'the loading frame must keep the same bottom bar state',
        );

        view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
        view.handleRenderedMessage({
          's': [_page('Second page', '/')],
        });
        await tester.pumpAndSettle();

        expect(
          tester.state(find.byType(LiveFloatingActionButton)),
          same(fabState),
          reason: 'the destination must update the FAB in place',
        );
        expect(
          tester.state(find.byType(LiveBottomNavigationBar)),
          same(barState),
          reason: 'the destination must update the bottom bar in place',
        );
        expect(find.text('Second page'), findsOneWidget);
      },
    );
  }
}

String _page(String title, String destination) => '''
<flutter>
  <viewBody floatingActionButtonLocation="centerDocked">
    <Text>$title</Text>
  </viewBody>
  <FloatingActionButton live-patch="$destination" shape="CircleBorder">
    <Icon name="add" />
  </FloatingActionButton>
  <BottomAppBar padding="0" shape="CircularNotchedRectangle">
    <BottomNavigationBar elevation="0">
      <BottomNavigationBarItem icon="home" label="Home" />
      <BottomNavigationBarItem icon="settings" label="Settings" />
    </BottomNavigationBar>
  </BottomAppBar>
</flutter>
''';
