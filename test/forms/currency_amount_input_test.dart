import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_currency_amount_input.dart';

import '../test_helpers.dart';

TextEditingValue typed(String text, [int? offset]) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: offset ?? text.length),
);

String? fieldValue() =>
    (find.byType(TextField).evaluate().first.widget as TextField)
        .controller
        ?.text;

main() async {
  group('CurrencyAmountFormatter.applyMask', () {
    test('groups thousands with spaces and uses the locale separator', () {
      expect(
        CurrencyAmountFormatter(decimalSeparator: ',').applyMask(1000.5),
        '1 000,50',
      );
      expect(
        CurrencyAmountFormatter(decimalSeparator: '.').applyMask(1000.5),
        '1 000.50',
      );
    });

    test('strips a trailing separator + 00 so whole numbers stay bare', () {
      expect(
        CurrencyAmountFormatter(decimalSeparator: ',').applyMask(1000),
        '1 000',
      );
      expect(
        CurrencyAmountFormatter(decimalSeparator: '.').applyMask(1000),
        '1 000',
      );
      expect(CurrencyAmountFormatter(decimalSeparator: '.').applyMask(0), '0');
    });

    test('a third decimal digit replaces the second one (reference quirk)', () {
      expect(
        CurrencyAmountFormatter(decimalSeparator: ',').applyMask(0.219),
        '0,29',
      );
    });
  });

  group('CurrencyAmountFormatter.numberValue', () {
    test('strips spaces and accepts either separator', () {
      var formatter = CurrencyAmountFormatter(decimalSeparator: ',');
      expect(formatter.numberValue('1 000,50'), 1000.5);
      expect(formatter.numberValue('1 000.50'), 1000.5);
      expect(formatter.numberValue(''), 0);
      expect(
        CurrencyAmountFormatter(decimalSeparator: '.').numberValue('1 000,50'),
        1000.5,
      );
    });
  });

  group('CurrencyAmountFormatter.formatEditUpdate', () {
    test('re-masks on every keystroke', () {
      var formatter = CurrencyAmountFormatter(decimalSeparator: ',');
      expect(formatter.formatEditUpdate(typed(''), typed('1')).text, '1');
      expect(
        formatter.formatEditUpdate(typed('1000'), typed('10000')),
        typed('10 000', 6),
      );
    });

    test('keeps a user-typed trailing separator and separator + zero', () {
      var formatter = CurrencyAmountFormatter(decimalSeparator: ',');
      expect(
        formatter.formatEditUpdate(typed('1 000'), typed('1 000,')),
        typed('1 000,'),
      );
      expect(
        formatter.formatEditUpdate(typed('1 000,'), typed('1 000,0')),
        typed('1 000,0'),
      );
    });

    test('rejects a second decimal separator', () {
      var formatter = CurrencyAmountFormatter(decimalSeparator: ',');
      expect(
        formatter.formatEditUpdate(typed('1,5'), typed('1,5,')),
        typed('1,5'),
      );
    });

    test('accepts the other separator when the value is entered at once', () {
      expect(
        CurrencyAmountFormatter(
          decimalSeparator: ',',
        ).formatEditUpdate(typed(''), typed('42.50')),
        typed('42,50'),
      );
      expect(
        CurrencyAmountFormatter(
          decimalSeparator: '.',
        ).formatEditUpdate(typed(''), typed('42,50')),
        typed('42.50'),
      );
    });

    test('deleting a thousands space deletes the adjacent digit', () {
      var formatter = CurrencyAmountFormatter(decimalSeparator: ',');
      // cursor was after "1 0" in "1 000", the space got deleted -> "1 00"
      expect(
        formatter.formatEditUpdate(typed('1 000', 3), typed('1 00', 2)),
        typed('100', 1),
      );
    });
  });

  group('CurrencyAmountInput widget', () {
    Future<(LiveView, FakeLiveSocket)> renderInput(
      WidgetTester tester, {
      String decimalSeparator = ',',
      String initialValue = '',
    }) async {
      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            '''
              <Form phx-change="validate" phx-submit="save">
                <CurrencyAmountInput name="amount" initialValue="$initialValue"
                                     label="Initial balance"
                                     decimalSeparator="$decimalSeparator" />
                <ElevatedButton type="submit">Save</ElevatedButton>
              </Form>
            ''',
          ],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      return (view, server);
    }

    testWidgets('shows the masked initial value', (tester) async {
      var (_, _) = await renderInput(tester, initialValue: '1 000,50');
      expect(fieldValue(), '1 000,50');
    });

    testWidgets('masks a dot-separated value typed at once in a comma locale', (
      tester,
    ) async {
      var (_, server) = await renderInput(tester);

      await tester.enterText(find.byType(TextField), '42.50');
      await tester.pumpAndSettle();

      expect(fieldValue(), '42,50');
      expect(
        server.lastChannelAction,
        liveEvents.phxFormValidate('validate', 'amount=42%2C50&_target=amount'),
      );
    });

    testWidgets('submits the masked value like any other form field', (
      tester,
    ) async {
      var (_, server) = await renderInput(tester, decimalSeparator: '.');

      await tester.enterText(find.byType(TextField), '10000');
      await tester.pumpAndSettle();
      expect(fieldValue(), '10 000');

      await tester.tap(find.text('Save'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        server.lastChannelAction.toString(),
        contains('event: save, value: amount=10+000'),
      );
    });
  });
}
