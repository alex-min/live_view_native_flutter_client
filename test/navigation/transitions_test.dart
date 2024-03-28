import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/socket/message.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';

import '../test_helpers.dart';

main() async {
  testGoldens('transitions', (tester) async {
    loadAppFonts();
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
        <flutter>
          <AppBar><Text as="title">My App</Text></AppBar>
          <viewBody>
            <Container decoration="background: green">
              <link live-patch="/second-page" />
            </Container>
          </viewBody>
          <BottomNavigationBar initialValue="0" selectedItemColor="blue-500">
            <BottomNavigationBarItem icon="display_settings" label="Display Settings" />
            <BottomNavigationBarItem icon="work" label="Second option" />
            <BottomNavigationBarItem icon="done" label="Done" />
            <BottomNavigationBarItem icon="drafts" label="Drafts" />
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

    view.handleMessage(LiveMessage(event: 'phx_close'));
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
          <BottomNavigationBar initialValue="1" selectedItemColor="blue-500">
            <BottomNavigationBarItem icon="display_settings" label="Display Settings" />
            <BottomNavigationBarItem icon="work" label="Second option" />
            <BottomNavigationBarItem icon="done" label="Done" />
            <BottomNavigationBarItem icon="drafts" label="Drafts" />
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
