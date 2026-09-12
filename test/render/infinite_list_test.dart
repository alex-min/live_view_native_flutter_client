import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('collapses its pinned header as transactions scroll', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 400));
    final children =
        List.generate(
          10,
          (index) => '<SizedBox height="50"><Text>Row $index</Text></SizedBox>',
        ).join();
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="100" '
              'pageSize="10" loadedStart="0" loadedCount="10" '
              'itemExtent="50" collapsibleHeaderHeight="200" '
              'collapsedHeaderHeight="80" loadKey="0">'
              '<Container><Text>Summary header</Text></Container>'
              '$children</InfiniteList>',
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
    final header = find.ancestor(
      of: find.text('Summary header'),
      matching: find.byType(ClipRect),
    );
    expect(find.byType(CustomScrollView), findsOneWidget);
    expect(tester.getSize(header.first).height, 200);

    scrollable.position.jumpTo(120);
    await tester.pumpAndSettle();

    expect(tester.getSize(header.first).height, 80);
    expect(find.text('Summary header'), findsOneWidget);
  });

  testWidgets(
    'keeps row widget state across parent rebuilds so dropdown menus stay open',
    (tester) async {
      tester.setScreenSize(const Size(400, 400));
      final children =
          List.generate(
            10,
            (index) =>
                '<SizedBox height="50"><ListTile><title><Text>Row $index</Text></title>'
                '<trailing><DropdownButton><icon><Icon name="more_vert" /></icon>'
                '<DropdownMenuItem label="Edit" value="edit" phx-click="edit_row" phx-value-id="7" />'
                '<DropdownMenuItem label="Delete" value="delete" />'
                '</DropdownButton></trailing></ListTile></SizedBox>',
          ).join();
      final (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<InfiniteList phx-load-page="load_page" totalCount="10" '
                'pageSize="10" loadedStart="0" loadedCount="10" '
                'itemExtent="50">$children</InfiniteList>',
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert).first);
      await tester.pumpAndSettle();

      // The dropdown menu is a route owned by the row's State; before the
      // children were cached, any parent rebuild re-parsed the rows with new
      // keys, disposed the state and removed the just-opened menu.
      expect(find.text('Edit'), findsWidgets);
      expect(find.text('Delete'), findsWidgets);

      // Tapping an item sends its phx-click event and dismisses the menu.
      await tester.tap(find.text('Edit').last);
      await tester.pumpAndSettle();
      expect(
        server.lastChannelAction,
        liveEvents.phxClick({'id': '7'}, eventName: 'edit_row'),
      );
    },
  );

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

  testWidgets('does not request from an offstage route with the same URL', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 400));
    final (view, server) = await connect(
      LiveView(),
      url: 'http://localhost:9999/transactions',
      rendered: {
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="1000" '
              'pageSize="10" loadedStart="0" loadedCount="10" '
              'itemExtent="50" loadKey="old">'
              '<SizedBox height="50"><Text>Old row</Text></SizedBox>'
              '</InfiniteList>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.currentUrl = '/edit';
    view.handleRenderedMessage({
      's': ['<viewBody><Text>Edit</Text></viewBody>'],
    });
    await tester.pumpAndSettle();

    view.currentUrl = '/transactions';
    view.handleRenderedMessage({
      's': [
        '<InfiniteList phx-load-page="load_page" totalCount="999" '
            'pageSize="10" loadedStart="0" loadedCount="10" '
            'itemExtent="50" loadKey="new">'
            '<SizedBox height="50"><Text>New row</Text></SizedBox>'
            '</InfiniteList>',
      ],
    });
    await tester.pumpAndSettle();

    final lists = find.byType(LiveInfiniteList, skipOffstage: false);
    expect(lists, findsNWidgets(2));
    final oldScrollable = tester.state<ScrollableState>(
      find.descendant(
        of: lists.first,
        matching: find.byType(Scrollable, skipOffstage: false),
        skipOffstage: false,
      ),
    );
    final actionsBeforeOldScroll = List.of(server.lastChannelActions!);

    oldScrollable.position.jumpTo(oldScrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, actionsBeforeOldScroll);
  });

  testWidgets(
    'restores an opted-in virtual list after returning to its route',
    (tester) async {
      tester.setScreenSize(const Size(400, 400));
      final (view, server) = await connect(
        LiveView(),
        url: 'http://localhost:9999/transactions',
        rendered: {
          's': [
            '<InfiniteList phx-load-page="load_page" totalCount="1000" '
                'pageSize="10" loadedStart="0" loadedCount="10" '
                'itemExtent="50" restorationId="transactions" loadKey="old">'
                '<SizedBox height="50"><Text>Old row</Text></SizedBox>'
                '</InfiniteList>',
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      final originalScrollable = tester.state<ScrollableState>(
        find.descendant(
          of: find.byType(LiveInfiniteList),
          matching: find.byType(Scrollable),
        ),
      );
      originalScrollable.position.jumpTo(25000);
      await tester.pumpAndSettle();

      view.currentUrl = '/edit';
      view.handleRenderedMessage({
        's': ['<viewBody><Text>Edit</Text></viewBody>'],
      });
      await tester.pumpAndSettle();

      view.currentUrl = '/transactions';
      view.handleRenderedMessage({
        's': [
          '<InfiniteList phx-load-page="load_page" totalCount="999" '
              'pageSize="10" loadedStart="0" loadedCount="10" '
              'itemExtent="50" restorationId="transactions" loadKey="new">'
              '<SizedBox height="50"><Text>Updated row</Text></SizedBox>'
              '</InfiniteList>',
        ],
      });
      await tester.pumpAndSettle();

      final returnedScrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byType(LiveInfiniteList),
              matching: find.byType(Scrollable),
            )
            .hitTestable(),
      );
      expect(returnedScrollable.position.pixels, 25000);
      expect(
        server.lastChannelAction,
        liveEvents.phxClick({'offset': 50}, eventName: 'load_page'),
      );
    },
  );

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
