import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testGoldens('appbar', (tester) async {
    loadAppFonts();
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
      <Scaffold>
        <BottomNavigationBar>
          <BottomNavigationBarItem live-patch="/second-page" icon="display_settings" label="Display Settings" />
          <BottomNavigationBarItem phx-click="inc" icon="work" label="Second option" />
          <BottomNavigationBarItem icon="done" label="Done" />
          <BottomNavigationBarItem icon="drafts" label="Drafts" />
        </BottomNavigationBar>
      </Scaffold>
      """
      ]
    });

    await tester.runLiveView(view);

    await tester.pumpAndSettle();

    await expectLater(find.byType(MaterialApp),
        matchesGoldenFile('bottom_navigation_bar.png'));
  });
}
