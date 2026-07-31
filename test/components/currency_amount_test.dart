import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  Future<LiveView> renderAmount(WidgetTester tester, String xml) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <flutter>
            <viewBody>
              $xml
            </viewBody>
          </flutter>
        ''',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pump();
    return view;
  }

  Text textWidget(String text) =>
      find.text(text).evaluate().first.widget as Text;

  testWidgets('renders the server-formatted text', (tester) async {
    await renderAmount(tester, '<CurrencyAmount text="1 000,50 €" />');

    expect(find.text('1 000,50 €'), findsOneWidget);
  });

  testWidgets('applies the color attribute, red when negative', (tester) async {
    await renderAmount(
      tester,
      '<CurrencyAmount text="€-5.00" color="#F44336" />',
    );

    expect(textWidget('€-5.00').style?.color, const Color(0xFFF44336));
  });

  testWidgets('merges the color into the extra text style', (tester) async {
    await renderAmount(
      tester,
      '<CurrencyAmount text="€42.50" color="#4CAF50" style="fontWeight: bold" />',
    );

    var text = textWidget('€42.50');
    expect(text.style?.color, const Color(0xFF4CAF50));
    expect(text.style?.fontWeight, FontWeight.bold);
  });

  testWidgets('updates when the server sends a diff', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<CurrencyAmount text="', '" color="#4CAF50" />'],
        '0': '€100.50',
      },
    );
    await tester.runLiveView(view);
    await tester.pump();
    expect(find.text('€100.50'), findsOneWidget);

    view.handleDiffMessage({'0': '€-20.25'});
    await tester.pump();
    expect(find.text('€-20.25'), findsOneWidget);
  });
}
