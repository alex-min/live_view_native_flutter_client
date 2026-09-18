import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets(
    'segmented button resolves selected and unselected label colors per state',
    (tester) async {
      var view =
          LiveView()..handleRenderedMessage({
            's': [
              '''
<flutter>
  <viewBody>
    <SegmentedButton name="billing" initialValue="yearly" showSelectedIcon="false" selectedForegroundColor="#191c2f" unselectedForegroundColor="#cbd5e1">
      <ButtonSegment name="monthly" label="Monthly" />
      <ButtonSegment name="yearly" label="Yearly" />
    </SegmentedButton>
  </viewBody>
</flutter>
''',
            ],
          });

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      final segmented = find.byType(SegmentedButton<String>);
      expect(segmented, findsOneWidget);

      Color? labelColor(String text) {
        final elements =
            find
                .descendant(of: segmented, matching: find.text(text))
                .evaluate();
        expect(elements, isNotEmpty, reason: 'label $text should render');
        return DefaultTextStyle.of(elements.first).style.color;
      }

      // Yearly is selected: dark label on the white pill. Monthly is not:
      // light label on the dark container.
      expect(labelColor('Yearly'), const Color(0xff191c2f));
      expect(labelColor('Monthly'), const Color(0xffcbd5e1));

      // Selecting the other segment flips the label colors.
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();

      expect(labelColor('Monthly'), const Color(0xff191c2f));
      expect(labelColor('Yearly'), const Color(0xffcbd5e1));
    },
  );
}
