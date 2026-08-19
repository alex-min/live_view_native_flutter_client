import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';

import '../test_helpers.dart';

void main() {
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
