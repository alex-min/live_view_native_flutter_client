import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('detects bottom navigation bar inside nested dynamic components', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': [
            '<flutter><viewBody><Text>Home</Text></viewBody>',
            '</flutter>',
          ],
          '0': {
            // Outer dynamic component (e.g. a function component like
            // <.bottom_navigation_bar>) wrapping a conditional dynamic block.
            's': ['[[flutterState key=0]]'],
            '0': {
              // Inner dynamic component rendered when the conditional is true,
              // containing the actual BottomNavigationBar XML.
              's': [
                '<BottomNavigationBar>',
                '<BottomNavigationBarItem icon="home" label="Home" />',
                '<BottomNavigationBarItem icon="settings" label="Settings" />',
                '</BottomNavigationBar>',
              ],
            },
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
      view.router.pages.last.widgets.any((w) => w is LiveBottomNavigationBar),
      isTrue,
      reason:
          'RootScaffold should discover a BottomNavigationBar rendered inside nested dynamic components',
    );
  });
}
