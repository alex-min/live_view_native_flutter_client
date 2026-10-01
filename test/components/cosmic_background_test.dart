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
    final paint = tester
        .widgetList<CustomPaint>(find.byType(CustomPaint))
        .firstWhere((widget) => widget.painter is CosmicAmbientPainter);
    expect(
      (paint.painter! as CosmicAmbientPainter).colors,
      Theme.of(tester.element(find.byType(LiveCosmicBackground))).colorScheme,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  test('ambient painter repaints when theme colors change', () {
    final light = CosmicAmbientPainter(
      colors: ColorScheme.fromSeed(seedColor: Colors.blue),
    );
    final dark = CosmicAmbientPainter(
      colors: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );
    final other = CosmicAmbientPainter(
      colors: ColorScheme.fromSeed(seedColor: Colors.green),
    );

    expect(light.shouldRepaint(light), isFalse);
    expect(light.shouldRepaint(dark), isTrue);
    expect(light.shouldRepaint(other), isTrue);
  });
}
