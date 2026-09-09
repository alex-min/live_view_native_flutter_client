import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_balance_chart.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders server balance points as a native painted chart', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<BalanceChart points="80,120,105" '
              'directions="expense,income,current" height="142" '
              'lineColor="#8D63FF" />',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LiveBalanceChart), findsOneWidget);
    final chartPaint = find.byWidgetPredicate(
      (widget) =>
          widget is CustomPaint && widget.painter is BalanceHistoryPainter,
    );
    expect(
      tester
          .widget<SizedBox>(
            find.descendant(
              of: find.byType(LiveBalanceChart),
              matching: find.byWidgetPredicate(
                (widget) => widget is SizedBox && widget.height == 142,
              ),
            ),
          )
          .height,
      142,
    );
    final painter =
        tester.widget<CustomPaint>(chartPaint).painter!
            as BalanceHistoryPainter;
    expect(painter.points, [80, 120, 105]);
    expect(painter.directions, ['expense', 'income', 'current']);
    expect(painter.lineColor, const Color(0xFF8D63FF));
  });
}
