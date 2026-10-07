import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import '../test_helpers.dart';

void main() {
  testWidgets(
    'safe slot markup produces direct positioned children and responds to patches',
    (tester) async {
      final view =
          LiveView()..handleRenderedMessage({
            's': [
              '<flutter><viewBody><Stack>',
              '</Stack></viewBody></flutter>',
            ],
            '0': '<Positioned top="0" left="0"><Text>slot</Text></Positioned>',
          });
      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('slot'), findsOneWidget);
      expect(find.byType(Positioned), findsWidgets);
      view.handleDiffMessage({
        '0': '<Positioned top="10" left="10"><Text>updated</Text></Positioned>',
      });
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('updated'), findsOneWidget);
      expect(find.text('slot'), findsNothing);
      view.handleDiffMessage({'0': ''});
      await tester.pumpAndSettle();
      expect(find.text('updated'), findsNothing);
    },
  );

  testWidgets('escaped vocabulary markup remains ordinary text', (
    tester,
  ) async {
    final view =
        LiveView()..handleRenderedMessage({
          's': [
            '<flutter><viewBody><Column>',
            '</Column></viewBody></flutter>',
          ],
          '0': '&lt;Text&gt;word&lt;/Text&gt;',
        });
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.text('<Text>word</Text>'), findsOneWidget);
  });
}
