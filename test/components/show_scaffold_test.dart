import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('show scaffold test', (tester) async {
    await loadAppFonts();
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <viewBody>
              <ScaffoldMessage kind="info">
                <Text>Scaffold Message</Text> 
              </ScaffoldMessage>
            </viewBody>
          </flutter>
        """
      ]
    });
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('show_scaffold_test.png'),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
  });

  testWidgets('remove scaffold after 5 seconds', (tester) async {
    await loadAppFonts();
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <viewBody>
              <ScaffoldMessage kind="info" duration="5000">
                <Text>Scaffold Message</Text> 
              </ScaffoldMessage>
            </viewBody>
          </flutter>
        """
      ]
    });
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('show_scaffold_test.png'),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.click({'key': 'info'}, eventName: 'lv:clear-flash'),
    ]);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('show_scaffold_removed_test.png'),
    );

    await view.handleRenderedMessage({
      's': [
        """
          <flutter>
            <viewBody>
              <ScaffoldMessage kind="info" duration="4000">
                <Text>Scaffold Message</Text> 
              </ScaffoldMessage>
            </viewBody>
          </flutter>
        """
      ]
    });
    await tester.pumpAndSettle(const Duration(seconds: 2));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('show_scaffold_test.png'),
    );

    await tester.pumpAndSettle(const Duration(seconds: 5));
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('show_scaffold_removed_test.png'),
    );

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.click({'key': 'info'}, eventName: 'lv:clear-flash'),
      liveEvents.click({'key': 'info'}, eventName: 'lv:clear-flash'),
    ]);
  });
}
