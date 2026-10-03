import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  const template = """
          <flutter>
            <viewBody floatingActionButtonLocation="centerDocked">
              <Container>hello</Container>
            </viewBody>
            <FloatingActionButton shape="CircleBorder"><Icon name="home" /></FloatingActionButton>
            <BottomAppBar elevation="10" padding="0" shape="CircularNotchedRectangle">
              <BottomNavigationBar
                showUnselectedLabel="true"
                backgroundColor="transparent"
                elevation="0"
                initialValue="1" selectedItemColor="blue-500">
                <BottomNavigationBarItem live-patch="/" icon="home" label="Page 1" />
                <BottomNavigationBarItem icon="home" label="Page 2" />
                <BottomNavigationBarItem icon="arrow_upward" label="Increment" />
                <BottomNavigationBarItem icon="arrow_downward" label="Decrement" />
              </BottomNavigationBar>
            </BottomAppBar>
          </flutter>
        """;

  testWidgets('BottomAppBar renders its band on narrow screens', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));
    await tester.checkScreenshot(template, 'bottom_app_bar_test.png');
    // screenshot assertion above already proves the bar painted
  });

  testWidgets(
    'BottomAppBar hides entirely on wide screens where the navigation bar collapses',
    (tester) async {
      tester.setScreenSize(const Size(900, 800));
      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [template],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);
    },
  );
}
