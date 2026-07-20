import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders cosmic background with base color and blurred blobs', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<CosmicBackground />'],
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LiveCosmicBackground), findsOneWidget);
    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('respects reduced motion and does not animate', (tester) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<CosmicBackground />'],
        });
    view.disableAnimations = true;

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var state =
        tester.state(find.byType(LiveCosmicBackground))
            as LiveCosmicBackgroundState;
    var initialTime = state.time.value;

    await tester.pump(const Duration(seconds: 1));

    expect(state.time.value, equals(initialTime));
  });

  testWidgets('animates blobs when animations are enabled', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<CosmicBackground />'],
      },
    );
    view.throttleSpammyCalls = false;
    view.catchExceptions = false;
    view.disableAnimations = false;

    await tester.pumpWidget(view.rootView);
    await tester.pump();

    var state =
        tester.state(find.byType(LiveCosmicBackground))
            as LiveCosmicBackgroundState;
    var initialTime = state.time.value;

    await tester.pump(const Duration(seconds: 1));

    expect(state.time.value, greaterThan(initialTime));
  });
}
