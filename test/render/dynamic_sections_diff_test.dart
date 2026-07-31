import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';

import '../test_helpers.dart';

main() async {
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
}
