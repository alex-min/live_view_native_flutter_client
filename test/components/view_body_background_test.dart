import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'cosmicBackground layers the animated background behind content',
    (tester) async {
      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<flutter><viewBody cosmicBackground="true">'
                '<Text>Dashboard</Text></viewBody></flutter>',
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pump();

      expect(find.byType(LiveCosmicBackground), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.byType(Stack), findsWidgets);
    },
  );
}
