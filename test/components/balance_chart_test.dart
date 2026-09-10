import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_balance_chart.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';

import '../test_helpers.dart';

void main() {
  test('interpolates chart values and scale when an outlier leaves view', () {
    final tween = BalanceChartFrameTween(
      begin: BalanceChartFrame(
        points: const [0, 1000, 20],
        directions: const ['expense', 'income', 'current'],
        selectedIndex: 2,
        windowStart: 0,
      ),
      end: BalanceChartFrame(
        points: const [10, 20, 30],
        directions: const ['income', 'income', 'current'],
        selectedIndex: 1,
        windowStart: 1,
      ),
    );

    final halfway = tween.lerp(0.5);
    expect(halfway.points, [5, 510, 25]);
    expect(halfway.minimum, 5);
    expect(halfway.maximum, 515);
    expect(tween.lerp(1).points, [10, 20, 30]);
    expect(tween.lerp(1).maximum, 30);
  });

  testWidgets('renders server balance points as a native painted chart', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<BalanceChart points="80,120,105" '
              'directions="expense,income,current" height="142" '
              'pointlabels="fOKCrDEyMApKYW4gMSwgMjAyNnzigqwxMDUKSmFuIDIsIDIwMjY" '
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
    expect(painter.labels.last, '€105\nJan 2, 2026');
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
              'collapsedHeight="120" '
              'compacttitle="Q29tcGFjdCBhY2NvdW50" '
              'searchlabel="U2VhcmNoIHRyYW5zYWN0aW9ucw" />'
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
      find
          .descendant(
            of: find.byType(LiveInfiniteList),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(painter().selectedIndex, 2);
    Opacity compactOpacity() => tester.widget<Opacity>(
      find.ancestor(
        of: find.text('Compact account'),
        matching: find.byType(Opacity),
      ),
    );
    expect(compactOpacity().opacity, 0);

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
    expect(compactOpacity().opacity, closeTo(1, 0.0001));
    expect(painter().topInset, closeTo(64, 0.0001));

    scrollable.position.jumpTo(130);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
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
      await tester.pump(const Duration(milliseconds: 600));
      expect(painter().selectedIndex, 12);
      expect(painter().windowStart, 40);

      scrollable.position.jumpTo(80 + 69 * 50);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
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
    await tester.pump(const Duration(milliseconds: 600));

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
