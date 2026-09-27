import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'widgets remounting offstage ignore the pending diff of the current page',
    (tester) async {
      final (view, _) = await connect(
        LiveView(),
        url: 'http://localhost:9999/form',
        rendered: {
          's': [
            '<viewBody><Column><Text>[[flutterState key=0]]</Text><DropdownButton name="account" initialValue="',
            '"><DropdownMenuItem value="1" label="Account" /></DropdownButton></Column></viewBody>',
          ],
          '0': '1',
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      // Navigate away: the form page stays mounted offstage.
      view.currentUrl = '/other';
      view.handleRenderedMessage({
        's': ['<viewBody><Text>Other</Text></viewBody>'],
      });
      await tester.pumpAndSettle();

      // A diff for the current page arrives and stays pending: no further
      // full render clears it. It reuses slot '0', which the offstage form
      // also has.
      view.handleDiffMessage({'0': 'Poison'});
      await tester.pumpAndSettle();
      expect(find.text('Other'), findsOneWidget);

      // Re-pumping the same view (host rebuild, test boundary) remounts
      // every widget while the pending diff is still stored. The offstage
      // form must not merge the current page's diff into its variables.
      await tester.pumpWidget(const SizedBox());
      await tester.pumpWidget(view.rootView);
      await tester.pumpAndSettle();

      final offstageDropdown = tester.widget<DropdownButton<String>>(
        find.byType(DropdownButton<String>, skipOffstage: false),
      );
      expect(offstageDropdown.value, '1');
      expect(tester.takeException(), isNull);
    },
  );
}
