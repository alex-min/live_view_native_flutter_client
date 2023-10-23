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
          <BottomNavigationBarIcon live-patch="/second-page" name="display_settings" label="Display Settings" />
          <BottomNavigationBarIcon phx-click="inc" name="work" label="Second option" />
          <BottomNavigationBarIcon name="done" label="Done" />
          <BottomNavigationBarIcon name="drafts" label="Drafts" />
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
