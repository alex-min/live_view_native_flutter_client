import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

main() async {
  testGoldens('transitions', (tester) async {
    loadAppFonts();
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
        <flutter>
          <AppBar><Text as="title">My App</Text></AppBar>
          <viewBody>
            <Container decoration="background: green">
              <link live-patch="/second-page" />
            </Container>
          </viewBody>
          <BottomNavigationBar currentIndex="0" selectedItemColor="blue-500">
            <BottomNavigationBarIcon name="display_settings" label="Display Settings" />
            <BottomNavigationBarIcon name="work" label="Second option" />
            <BottomNavigationBarIcon name="done" label="Done" />
            <BottomNavigationBarIcon name="drafts" label="Drafts" />
          </BottomNavigationBar>
        </flutter>
      """
      ]
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LiveLink));

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('transitions_test_loading.png'));

    expect(view.router.pages.map((p) => p.page.name),
        ['loading', '/', 'loading;/second-page']);

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [
        """
        <flutter>
          <AppBar><Text as="title">My App: Page 2</Text></AppBar>
          <viewBody>
            <Container decoration="background: green">
              Page 2
            </Container>
          </viewBody>
          <BottomNavigationBar currentIndex="1" selectedItemColor="blue-500">
            <BottomNavigationBarIcon name="display_settings" label="Display Settings" />
            <BottomNavigationBarIcon name="work" label="Second option" />
            <BottomNavigationBarIcon name="done" label="Done" />
            <BottomNavigationBarIcon name="drafts" label="Drafts" />
          </BottomNavigationBar>
        </flutter>
        """
      ]
    });

    await tester.pumpAndSettle();
    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('transitions_test_second_page.png'));
  });
}
