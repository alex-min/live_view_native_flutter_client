import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  Future<void> renderIndicator(WidgetTester tester, String attributes) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<flutter><viewBody><LinearProgressIndicator $attributes />'
              '</viewBody></flutter>',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pump();
  }

  testWidgets('maps progress indicator attributes', (tester) async {
    await renderIndicator(
      tester,
      'value="0.45" minHeight="8" color="#ff0000" '
      'backgroundColor="#0000ff" borderRadius="6" '
      'semanticsLabel="Spending" semanticsValue="45"',
    );

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.45);
    expect(indicator.minHeight, 8);
    expect(indicator.color, const Color(0xffff0000));
    expect(indicator.backgroundColor, const Color(0xff0000ff));
    expect(indicator.borderRadius, BorderRadius.circular(6));
    expect(indicator.semanticsLabel, 'Spending');
    expect(indicator.semanticsValue, '45');
  });

  testWidgets('clamps progress to the Material range', (tester) async {
    await renderIndicator(tester, 'value="1.5"');

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 1);
  });
}
