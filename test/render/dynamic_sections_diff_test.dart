import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('replaces section statics when an if/else switches back', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<Column>', '</Column>'],
          '0': {
            's': ['<Text>form ', '</Text>'],
            '0': 'ready',
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.text('form ready'), findsOneWidget);

    view.handleDiffMessage({
      '0': {
        's': ['<Column><Text>picker ', '</Text>', '</Column>'],
        '0': 'open',
        '1': {
          's': ['<Text>stale picker child</Text>'],
        },
      },
    });
    await tester.pumpAndSettle();
    expect(find.text('picker open'), findsOneWidget);

    view.handleDiffMessage({
      '0': {
        's': ['<Text>form ', '</Text>'],
        '0': 'restored',
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('form restored'), findsOneWidget);
    expect(find.text('stale picker child'), findsNothing);
    expect(find.textContaining('<Text>'), findsNothing);
  });

  testWidgets('diff emptying a comprehension and revealing a section', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<ListView>', '\n', '\n', '\n', '', '</ListView>'],
          '0': {
            's': ['<Text>row ', '</Text>'],
            'd': [
              ['A'],
            ],
          },
          '1': '',
          '2': '',
          '3': {
            's': ['<Text>static section</Text>'],
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('row A'), findsOneWidget);
    expect(find.text('static section'), findsOneWidget);

    view.handleDiffMessage({
      '0': {'d': []},
      '1': '',
      '2': {
        's': ['<Text>inactive (', ')</Text>'],
        '0': '1',
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('inactive (1)'), findsOneWidget);
    expect(find.text('row A'), findsNothing);
  });

  testWidgets('diff expanding a section slot into a comprehension', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': ['<ListView>', '\n', '</ListView>'],
          '0': {
            's': ['<Text>section</Text>', ''],
            '0': '',
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('section'), findsOneWidget);

    // Reveal the section content: the '' slot becomes a section wrapping
    // a comprehension.
    view.handleDiffMessage({
      '0': {
        '0': {
          '0': {
            's': ['<Text>row ', '</Text>'],
            'd': [
              ['B'],
            ],
          },
          's': ['\n', '\n'],
        },
      },
    });
    await tester.pumpAndSettle();

    expect(find.text('row B'), findsOneWidget);
  });

  testWidgets(
    'renders a conditional inside a virtual list whose content only appears in a diff',
    (tester) async {
      // Shape of the accounts screen: an InfiniteList flattens its dynamic
      // children, holding a list comprehension next to an inner conditional
      // that is empty on first render. When the diff fills the inner slot,
      // the new subtree must mount.
      var view =
          LiveView()..handleRenderedMessage({
            's': [
              '<InfiniteList phx-load-page="load_page" totalCount="2" '
                  'pageSize="2" loadedStart="0" loadedCount="2" '
                  'itemExtent="50"><Container><Text>HEADER</Text></Container>',
              '',
              '</InfiniteList>',
            ],
            '0': {
              's': ['<SizedBox height="50"><Text>active row</Text></SizedBox>'],
              'd': [[]],
            },
            '1': '',
          });

      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      expect(find.text('active row'), findsOneWidget);
      expect(find.text('Inactive accounts (1)'), findsNothing);

      view.handleDiffMessage({
        '0': {'d': []},
        '1': {
          's': [
            '<SizedBox height="50"><Text>Inactive accounts (1)</Text></SizedBox>',
          ],
        },
      });
      await tester.pump();
      await tester.pump();

      expect(find.text('active row'), findsNothing);
      expect(find.text('Inactive accounts (1)'), findsOneWidget);
    },
  );
}
