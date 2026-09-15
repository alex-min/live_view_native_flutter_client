import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders a static ambient wash without filtered layers', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<CosmicBackground />'],
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LiveCosmicBackground), findsOneWidget);
    expect(find.byType(ImageFiltered), findsNothing);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('ambient painter only repaints when the theme brightness changes', () {
    const light = CosmicAmbientPainter(isDark: false);

    expect(
      light.shouldRepaint(const CosmicAmbientPainter(isDark: false)),
      isFalse,
    );
    expect(
      light.shouldRepaint(const CosmicAmbientPainter(isDark: true)),
      isTrue,
    );
  });
}
