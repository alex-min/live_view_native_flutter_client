import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  Future<LiveView> renderInput(WidgetTester tester, String xml) async {
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
    await tester.pumpAndSettle();
    return view;
  }

  testWidgets(
    'hero appearance shows the currency prefix, large bold font and bar',
    (tester) async {
      await renderInput(tester, '''
      <Form phx-submit="save">
        <CurrencyAmountInput
          name="transaction[amount]"
          initialValue=""
          label="Amount"
          decimalSeparator="."
          appearance="hero"
          prefixText="€"
          barColor="#E2E2E8"
          barActiveColor="#4F46E5"
        />
      </Form>
    ''');

      var field = tester.widget<TextField>(find.byType(TextField));
      expect(field.style?.fontSize, 32);
      expect(field.style?.fontWeight, FontWeight.bold);
      expect(field.decoration?.prefixText, '€ ');

      // the bar under the input: a 2px track with a quarter-width active segment
      var bar = tester.widget<SizedBox>(
        find.byWidgetPredicate(
          (widget) => widget is SizedBox && widget.height == 2,
        ),
      );
      expect(
        find.descendant(of: find.byWidget(bar), matching: find.byType(Stack)),
        findsOneWidget,
      );
      var activeSegment = tester.widget<FractionallySizedBox>(
        find.descendant(
          of: find.byWidget(bar),
          matching: find.byType(FractionallySizedBox),
        ),
      );
      expect(activeSegment.widthFactor, 0.25);
      var activeRenderObject =
          find
                  .descendant(
                    of: find.byWidget(bar),
                    matching: find.byType(FractionallySizedBox),
                  )
                  .evaluate()
                  .first
                  .renderObject!
              as RenderBox;
      expect(activeRenderObject.size.height, 2);
    },
  );

  testWidgets('default appearance keeps the regular outlined look', (
    tester,
  ) async {
    await renderInput(tester, '''
      <Form phx-submit="save">
        <CurrencyAmountInput
          name="transaction[amount]"
          initialValue=""
          label="Amount"
          decimalSeparator="."
          decoration="filled: true"
        />
      </Form>
    ''');

    var field = tester.widget<TextField>(find.byType(TextField));
    expect(field.style, isNull);
    expect(field.decoration?.prefixText, isNull);
    expect(find.byType(Card), findsNothing);
  });

  testWidgets('validation errors from the server are displayed', (
    tester,
  ) async {
    await renderInput(tester, '''
      <Form phx-submit="save">
        <CurrencyAmountInput
          name="transaction[amount]"
          initialValue=""
          label="Amount"
          decimalSeparator="."
          appearance="hero"
          prefixText="€"
          errors='[{"message": "cant be blank", "options": {}}]'
        />
      </Form>
    ''');

    expect(find.text("cant be blank"), findsOneWidget);
  });
}
