import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('floating action button state persists across navigation', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [_page('First page', '/second-page', 'add')],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final initialState = tester.state(find.byType(LiveFloatingActionButton));

    await view.livePatch('/second-page');
    await tester.pump();

    expect(
      tester.state(find.byType(LiveFloatingActionButton)),
      same(initialState),
      reason: 'the loading route must retain the root floating button',
    );

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Second page', '/', 'edit')],
    });
    await tester.pumpAndSettle();

    expect(
      tester.state(find.byType(LiveFloatingActionButton)),
      same(initialState),
      reason: 'the destination must update rather than reinsert the button',
    );
    expect(find.byIcon(Icons.edit), findsOneWidget);
    expect(find.text('Second page'), findsOneWidget);
  });
}

String _page(String title, String destination, String icon) => '''
<flutter>
  <viewBody floatingActionButtonLocation="centerDocked">
    <Text>$title</Text>
  </viewBody>
  <FloatingActionButton live-patch="$destination" shape="CircleBorder">
    <Icon name="$icon" />
  </FloatingActionButton>
  <BottomAppBar padding="0" shape="CircularNotchedRectangle">
    <BottomNavigationBar elevation="0">
      <BottomNavigationBarItem icon="home" label="Home" />
      <BottomNavigationBarItem icon="settings" label="Settings" />
    </BottomNavigationBar>
  </BottomAppBar>
</flutter>
''';
