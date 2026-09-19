import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('wrap maps layout attributes and flattens dynamic children', (
    tester,
  ) async {
    final view =
        LiveView()..handleRenderedMessage({
          's': [
            '<flutter><viewBody><Wrap direction="vertical" alignment="spaceBetween" spacing="8" runAlignment="center" runSpacing="10" crossAxisAlignment="end">',
            '</Wrap></viewBody></flutter>',
          ],
          '0': {
            's': ['<Text>', '</Text>'],
            'd': [
              ['First'],
              ['Second'],
            ],
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final wrap = tester.widget<Wrap>(find.byType(Wrap));
    expect(wrap.direction, Axis.vertical);
    expect(wrap.alignment, WrapAlignment.spaceBetween);
    expect(wrap.spacing, 8);
    expect(wrap.runAlignment, WrapAlignment.center);
    expect(wrap.runSpacing, 10);
    expect(wrap.crossAxisAlignment, WrapCrossAlignment.end);
    expect(wrap.children, hasLength(2));
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
