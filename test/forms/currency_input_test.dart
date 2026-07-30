import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  Future<(LiveView, FakeLiveSocket)> renderInput(WidgetTester tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
            <Form phx-change="validate_currency" phx-submit="save_currency">
              <CurrencyInput name="user[default_currency]" initialValue="EUR"
                             label="Change currency" hint="Search a currency..."
                             emptyLabel="No currency matches your search.">
                <Option value="EUR" label="EUR (€) — Euro" flag="/images/flags/EUR.png" />
                <Option value="GBP" label="GBP (£) — British Pound" flag="/images/flags/GBP.png" />
                <Option value="USD" label="USD (\$) — US Dollar" flag="/images/flags/USD.png" />
              </CurrencyInput>
              <ElevatedButton type="submit">Save</ElevatedButton>
            </Form>
          """,
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    return (view, server);
  }

  testWidgets('shows the current value with the dropdown closed', (
    tester,
  ) async {
    var (_, _) = await renderInput(tester);

    // the current selection is shown, the dropdown is closed
    expect(find.text('EUR (€) — Euro'), findsOneWidget);
    expect(find.text('USD (\$) — US Dollar'), findsNothing);
  });

  testWidgets('opens a floating dropdown, filters and picks a currency', (
    tester,
  ) async {
    var (_, server) = await renderInput(tester);

    // open the dropdown
    await tester.tap(find.text('EUR (€) — Euro'));
    await tester.pumpAndSettle();
    expect(find.text('USD (\$) — US Dollar'), findsOneWidget);
    expect(find.text('GBP (£) — British Pound'), findsOneWidget);

    // filter client-side
    await tester.enterText(find.byType(TextField), 'dollar');
    await tester.pumpAndSettle();
    expect(find.text('USD (\$) — US Dollar'), findsOneWidget);
    expect(find.text('GBP (£) — British Pound'), findsNothing);

    // pick USD: the dropdown closes, the field shows it and the form is
    // notified with the currency code
    await tester.tap(find.text('USD (\$) — US Dollar'));
    await tester.pumpAndSettle();
    expect(find.byType(ListTile), findsNothing);
    expect(find.text('USD (\$) — US Dollar'), findsOneWidget);
    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'validate_currency',
        'user%5Bdefault_currency%5D=USD&_target=user%5Bdefault_currency%5D',
      ),
    );
  });

  testWidgets('shows the empty label when nothing matches', (tester) async {
    var (_, _) = await renderInput(tester);

    await tester.tap(find.text('EUR (€) — Euro'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('No currency matches your search.'), findsOneWidget);
  });

  testWidgets('reads the options from a server-side for-loop', (tester) async {
    // The server sends a :for loop as template statics + 'd' rows behind a
    // [[flutterState key=N]] placeholder, not as real XML children.
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
            <Form phx-change="validate_currency" phx-submit="save_currency">
              <CurrencyInput name="user[default_currency]" initialValue="EUR"
                             label="Change currency" hint="Search a currency...">
          """,
          """
              </CurrencyInput>
            </Form>
          """,
        ],
        '0': {
          's': ['<Option value="', '" label="', '" flag="', '" />'],
          'd': [
            ['EUR', 'EUR (€) — Euro', '/images/flags/EUR.png'],
            ['USD', 'USD (\$) — US Dollar', '/images/flags/USD.png'],
          ],
        },
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('EUR (€) — Euro'), findsOneWidget);

    await tester.tap(find.text('EUR (€) — Euro'));
    await tester.pumpAndSettle();
    expect(find.text('USD (\$) — US Dollar'), findsOneWidget);

    await tester.tap(find.text('USD (\$) — US Dollar'));
    await tester.pumpAndSettle();
    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'validate_currency',
        'user%5Bdefault_currency%5D=USD&_target=user%5Bdefault_currency%5D',
      ),
    );
  });
}
