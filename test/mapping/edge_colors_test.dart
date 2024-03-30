import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/edge_colors.dart';

void main() {
  testWidgets('material text style', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (BuildContext context) {
          expect(
            getEdgeColors(context, ""),
            const EdgeColors.all(Colors.black),
          );
          expect(
            getEdgeColors(context, "red"),
            const EdgeColors.all(Colors.red),
          );
          expect(
            getEdgeColors(context, "red blue"),
            const EdgeColors.symmetric(
              vertical: Colors.red,
              horizontal: Colors.blue,
            ),
          );
          expect(
            getEdgeColors(context, "red blue green"),
            const EdgeColors.only(
              top: Colors.red,
              right: Colors.blue,
              bottom: Colors.green,
              left: Colors.blue,
            ),
          );
          expect(
            getEdgeColors(context, "red blue green pink"),
            const EdgeColors.only(
              top: Colors.red,
              right: Colors.blue,
              bottom: Colors.green,
              left: Colors.pink,
            ),
          );

          return const SizedBox.shrink();
        },
      ),
    );
  });
}
