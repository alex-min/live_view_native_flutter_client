import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('outline TextField uses theme outline color for its border', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <viewBody>
              <TextField decoration="border: outline" />
            </viewBody>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var context = tester.element(find.byType(InputDecorator));
    var expectedColor = Theme.of(context).colorScheme.outline;

    var decorator = tester.widget<InputDecorator>(find.byType(InputDecorator));
    var enabledBorder =
        decorator.decoration.enabledBorder as OutlineInputBorder;
    var focusedBorder =
        decorator.decoration.focusedBorder as OutlineInputBorder;
    var primaryColor = Theme.of(context).colorScheme.primary;

    expect(enabledBorder.borderSide.color, expectedColor);
    expect(focusedBorder.borderSide.color, primaryColor);
  });
}
