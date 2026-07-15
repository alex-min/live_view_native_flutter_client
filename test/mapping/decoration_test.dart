import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';

void main() {
  testWidgets('parse solid color decoration', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration = getDecoration(context, 'background: #5353E5');
          expect(decoration, isA<BoxDecoration>());
          expect((decoration as BoxDecoration).color, const Color(0xFF5353E5));
          return const SizedBox.shrink();
        },
      ),
    );
  });

  testWidgets('parse linear gradient decoration', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration = getDecoration(context, 'gradient: { linear #5353E5 #D94FC3 }');
          expect(decoration, isA<BoxDecoration>());
          var gradient = (decoration as BoxDecoration).gradient as LinearGradient;
          expect(gradient.colors, [const Color(0xFF5353E5), const Color(0xFFD94FC3)]);
          expect(gradient.stops, [0.0, 1.0]);
          return const SizedBox.shrink();
        },
      ),
    );
  });

  testWidgets('parse radial gradient with custom stops', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration =
              getDecoration(context, 'gradient: { radial #5353E5 0.0 #D94FC3 0.75 #232840 1.0 }');
          expect(decoration, isA<BoxDecoration>());
          var gradient = (decoration as BoxDecoration).gradient as RadialGradient;
          expect(gradient.colors, [
            const Color(0xFF5353E5),
            const Color(0xFFD94FC3),
            const Color(0xFF232840),
          ]);
          expect(gradient.stops, [0.0, 0.75, 1.0]);
          return const SizedBox.shrink();
        },
      ),
    );
  });

  testWidgets('parse theme color in gradient', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration =
              getDecoration(context, 'gradient: { radial @theme.colorScheme.primary @theme.colorScheme.secondary }');
          expect(decoration, isA<BoxDecoration>());
          var gradient = (decoration as BoxDecoration).gradient as RadialGradient;
          expect(
            gradient.colors,
            [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          );
          return const SizedBox.shrink();
        },
      ),
    );
  });
}
