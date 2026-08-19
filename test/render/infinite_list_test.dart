import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'virtualizes the full extent and loads arbitrary pages in either direction',
    (tester) async {
      tester.setScreenSize(const Size(400, 400));
      final children =
          List.generate(
            30,
            (index) =>
                '<SizedBox height="50"><Text>Row $index</Text></SizedBox>',
          ).join();
      final (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<InfiniteList phx-load-page="load_page" totalCount="1000" '
                'pageSize="10" loadedStart="',
            '" loadedCount="30" itemExtent="50" loadKey="',
            '">$children</InfiniteList>',
          ],
          '0': '0',
          '1': '0',
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
      expect(scrollable.position.maxScrollExtent, closeTo(49600, 1));
      expect(find.textContaining('Row ').evaluate().length, lessThan(30));

      scrollable.position.jumpTo(25000);
      await tester.pumpAndSettle();
      expect(
        server.lastChannelAction,
        liveEvents.phxClick({'offset': 50}, eventName: 'load_page'),
      );

      view.handleDiffMessage({'0': '490', '1': '490'});
      await tester.pumpAndSettle();
      expect(scrollable.position.pixels, 25000);
      expect(scrollable.position.maxScrollExtent, closeTo(49600, 1));
      expect(find.textContaining('Row ').evaluate().length, lessThan(30));

      scrollable.position.jumpTo(20000);
      await tester.pumpAndSettle();
      expect(
        server.lastChannelAction,
        liveEvents.phxClick({'offset': 40}, eventName: 'load_page'),
      );

      view.handleDiffMessage({'0': '390', '1': '390'});
      await tester.pumpAndSettle();

      for (var cycle = 0; cycle < 20; cycle++) {
        final firstLoaded = cycle.isEven ? 90 : 690;
        scrollable.position.jumpTo((firstLoaded + 10) * 50);
        await tester.pumpAndSettle();
        view.handleDiffMessage({'0': '$firstLoaded', '1': 'cycle-$cycle'});
        await tester.pumpAndSettle();

        expect(find.textContaining('Row ').evaluate().length, lessThan(30));
      }

      expect(server.lastChannelActions, hasLength(23));
    },
  );

  testWidgets(
    'requests one page near the end and rearms after loadKey changes',
    (tester) async {
      tester.setScreenSize(const Size(400, 400));
      final children =
          List.generate(
            12,
            (index) =>
                '<SizedBox height="100"><Text>Row $index</Text></SizedBox>',
          ).join();
      final (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<InfiniteList phx-load-more="load_more" hasMore="true" loadKey="',
            '">$children</InfiniteList>',
          ],
          '0': '1',
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      expect(find.byType(LiveInfiniteList), findsOneWidget);
      expect(server.lastChannelActions, [liveEvents.join]);

      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();

      expect(server.lastChannelActions, [
        liveEvents.join,
        liveEvents.phxClick({}, eventName: 'load_more'),
      ]);

      await tester.drag(find.byType(ListView), const Offset(0, -200));
      await tester.pumpAndSettle();
      expect(server.lastChannelActions, [
        liveEvents.join,
        liveEvents.phxClick({}, eventName: 'load_more'),
      ]);

      view.handleDiffMessage({'0': '2'});
      await tester.pumpAndSettle();

      expect(server.lastChannelActions, [
        liveEvents.join,
        liveEvents.phxClick({}, eventName: 'load_more'),
        liveEvents.phxClick({}, eventName: 'load_more'),
      ]);
    },
  );

  testWidgets('does not request pages after its route becomes offstage', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 400));
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="1000" '
              'pageSize="10" loadedStart="0" loadedCount="10" '
              'itemExtent="50" loadKey="0">'
              '<SizedBox height="50"><Text>Row</Text></SizedBox>'
              '</InfiniteList>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    final actionsBeforeLeaving = List.of(server.lastChannelActions!);
    view.currentUrl = '/another-route';

    final scrollable = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(LiveInfiniteList),
        matching: find.byType(Scrollable),
      ),
    );
    scrollable.position.jumpTo(25000);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, actionsBeforeLeaving);
  });

  testWidgets('does not request a page when hasMore is false', (tester) async {
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<InfiniteList phx-load-more="load_more" hasMore="false">'
              '<Text>Only row</Text>'
              '</InfiniteList>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [liveEvents.join]);
  });

  testWidgets('renders rows appended by a server diff', (tester) async {
    final view =
        LiveView()..handleRenderedMessage({
          's': [
            '<InfiniteList hasMore="false" loadKey="',
            '">',
            '</InfiniteList>',
          ],
          '0': '1',
          '1': {
            's': ['<Text>', '</Text>'],
            'd': [
              ['First'],
            ],
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsNothing);

    view.handleDiffMessage({
      '0': '2',
      '1': {
        'd': [
          ['First'],
          ['Second'],
        ],
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });
}
