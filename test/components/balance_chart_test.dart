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

  testWidgets(
    'slides an older point window before selection reaches the edge',
    (tester) async {
      tester.setScreenSize(const Size(400, 400));
      final points = List.generate(121, (index) => index).join(',');
      final directions = List.filled(121, 'expense').join(',');
      final rows =
          List.generate(
            121,
            (index) =>
                '<SizedBox height="50"><Text>Row $index</Text></SizedBox>',
          ).join();
      final (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<InfiniteList phx-load-page="load_page" totalCount="160" '
                'pageSize="40" loadedStart="0" loadedCount="121" '
                'itemExtent="50" collapsibleHeaderHeight="200" '
                'collapsedHeaderHeight="120">'
                '<BalanceChart points="$points" directions="$directions" '
                'pointOffset="0" windowSize="80" edgeMargin="12" '
                'height="160" collapsedHeight="120" />'
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

      expect(painter().points.length, 80);
      expect(painter().windowStart, 41);

      scrollable.position.jumpTo(80 + 68 * 50);
      await tester.pump();
      expect(painter().selectedIndex, 12);
      expect(painter().windowStart, 40);

      scrollable.position.jumpTo(80 + 69 * 50);
      await tester.pump();
      expect(painter().windowStart, 39);
      expect(painter().selectedIndex, 12);
      expect(painter().points.first, 39);
    },
  );

  testWidgets('maps deep list offsets into a newly loaded chart window', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 400));
    final points = List.generate(121, (index) => index).join(',');
    final rows =
        List.generate(
          121,
          (index) => '<SizedBox height="50"><Text>Row $index</Text></SizedBox>',
        ).join();
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="300" '
              'pageSize="40" loadedStart="80" loadedCount="121" '
              'itemExtent="50" collapsibleHeaderHeight="200" '
              'collapsedHeaderHeight="120">'
              '<BalanceChart points="$points" pointOffset="80" '
              'windowSize="80" edgeMargin="12" height="160" '
              'collapsedHeight="120" />$rows</InfiniteList>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(LiveInfiniteList),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(80 + 140 * 50);
    await tester.pump();

    final painter =
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
    expect(painter.selectedIndex, 19);
    expect(painter.windowStart, 41);
  });
}
