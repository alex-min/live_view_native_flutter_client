import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/input_decoration.dart';

void main() {
  testWidgets('parse filled input with border radius and content padding', (
    tester,
  ) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration = getInputDecoration(
            context,
            'filled: true; fillColor: #3A4363; border: outline; borderRadius: 12; contentPadding: { 12 14 }',
          );
          expect(decoration.filled, isTrue);
          expect(decoration.fillColor, const Color(0xFF3A4363));
          expect(decoration.border, isA<OutlineInputBorder>());
          expect(
            (decoration.border as OutlineInputBorder).borderRadius,
            BorderRadius.circular(12),
          );
          expect(
            decoration.contentPadding,
            const EdgeInsets.only(top: 12, bottom: 12, left: 14, right: 14),
          );
          return const SizedBox.shrink();
        },
      ),
    );
  });

  testWidgets('parse input with no border', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          var decoration = getInputDecoration(context, 'border: none');
          expect(decoration.border, InputBorder.none);
          return const SizedBox.shrink();
        },
      ),
    );
  });
}
