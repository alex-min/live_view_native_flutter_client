import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  LiveView renderedView() =>
      LiveView()..handleRenderedMessage({
        's': ['<flutter><viewBody><Row>', '</Row></viewBody></flutter>'],
        '0': {
          's': ['<ActionChip label="', '" />'],
          'd': [
            ['chip A'],
            ['chip B'],
            ['chip C'],
          ],
        },
      });

  testWidgets('row lays out comprehension children horizontally', (
    tester,
  ) async {
    var view = renderedView();
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.children.length, 3);
    expect(
      row.children.every(
        (child) =>
            child is ActionChip ||
            child.runtimeType.toString().contains('LiveActionChip'),
      ),
      isTrue,
      reason:
          'The resolved chips should be direct flex children, not a '
          'wrapped column',
    );
    expect(find.text('chip A'), findsOneWidget);
    expect(find.text('chip B'), findsOneWidget);
    expect(find.text('chip C'), findsOneWidget);
  });

  testWidgets('row rebuilds flattened children when the comprehension diffs', (
    tester,
  ) async {
    var view = renderedView();
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {
        'd': [
          ['chip D'],
        ],
      },
    });
    await tester.pumpAndSettle();

    final row = tester.widget<Row>(find.byType(Row));
    expect(row.children.length, 1);
    expect(find.text('chip D'), findsOneWidget);
    expect(find.text('chip A'), findsNothing);
  });
}
