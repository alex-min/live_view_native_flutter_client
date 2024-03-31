import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';

void main() {
  testWidgets('parse colors', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          expect(
            getColor(context, "#FAD"),
            const Color(0xFFFFAADD),
          );
          expect(
            getColor(context, "#000000"),
            Colors.black,
          );
          expect(
            getColor(context, "red"),
            Colors.red,
          );
          expect(
            getColor(context, "@theme.colorScheme.primary"),
            Theme.of(context).colorScheme.primary,
          );

          return const SizedBox.shrink();
        },
      ),
    );
  });
}
