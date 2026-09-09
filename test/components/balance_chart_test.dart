import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_balance_chart.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';

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
    expect(painter.selectedIndex, 2);
    expect(painter.lineColor, const Color(0xFF8D63FF));
  });

  testWidgets('shrinks and follows the transaction crossing the list', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 400));
    final rows =
        List.generate(
          8,
          (index) => '<SizedBox height="50"><Text>Row $index</Text></SizedBox>',
        ).join();
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="20" '
              'pageSize="8" loadedStart="0" loadedCount="8" itemExtent="50" '
              'collapsibleHeaderHeight="200" collapsedHeaderHeight="120">'
              '<BalanceChart points="80,90,100" '
              'directions="expense,income,current" height="160" '
              'collapsedHeight="120" />'
              '$rows</InfiniteList>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    BalanceHistoryPainter painter() =>
        tester
                .widget<CustomPaint>(
                  find.byWidgetPredicate(
                    (widget) =>
                        widget is CustomPaint &&
                        widget.painter is BalanceHistoryPainter,
                  ),
                )
                .painter!
            as BalanceHistoryPainter;

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(LiveInfiniteList),
        matching: find.byType(Scrollable),
      ),
    );
    expect(painter().selectedIndex, 2);

    scrollable.position.jumpTo(80);
    await tester.pump();
    expect(painter().selectedIndex, 2);
    expect(
      tester
          .widget<SizedBox>(
            find.descendant(
              of: find.byType(LiveBalanceChart),
              matching: find.byWidgetPredicate(
                (widget) => widget is SizedBox && widget.height == 120,
              ),
            ),
          )
          .height,
      120,
    );

    scrollable.position.jumpTo(130);
    await tester.pump();
    expect(painter().selectedIndex, 1);
  });
}
