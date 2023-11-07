import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('looks okay', (tester) async {
    await loadAppFonts();
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <BottomSheet><Container width="infinity" height="200">bottom sheet</Container></BottomSheet>
            <viewBody>
              <Column>
                <ElevatedButton phx-click="${baseActions.showBottomSheet}">open</ElevatedButton>
              </Column>
            </viewBody>
          </flutter>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('bottom sheet'), findsNothing);

    await tester.tap(find.text('open'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(find.text('bottom sheet'), findsOneWidget);

    await expectLater(
        find.byType(MaterialApp), matchesGoldenFile('bottom_sheet_test.png'));
  });
}
