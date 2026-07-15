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

  testWidgets('animates blobs when animations are enabled', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': ['<CosmicBackground />'],
    });
    view.throttleSpammyCalls = false;
    view.catchExceptions = false;
    view.disableAnimations = false;

    await tester.pumpWidget(view.rootView);
    await tester.pump();

    var state = tester.state(find.byType(LiveCosmicBackground))
        as LiveCosmicBackgroundState;
    var initialValues = state.controllers.map((c) => c.value).toList();

    await tester.pump(const Duration(seconds: 1));

    for (var i = 0; i < state.controllers.length; i++) {
      expect(state.controllers[i].isAnimating, isTrue);
      expect(state.controllers[i].value, isNot(equals(initialValues[i])));
    }
  });
}
