import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders cosmic background with base color and blurred blobs',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<CosmicBackground />'],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LiveCosmicBackground), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('respects reduced motion and does not animate', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<CosmicBackground />'],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var state = tester.state(find.byType(LiveCosmicBackground))
        as LiveCosmicBackgroundState;
    for (var controller in state.controllers) {
      expect(controller.isAnimating, isFalse);
    }
  });
}
