import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  Future<(LiveView, FakeLiveSocket)> renderInput(WidgetTester tester) async {
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <Form phx-change="validate" phx-submit="save">
            <DateInput name="transaction[spent_at]"
                       initialValue="2026-07-15"
                       displayValue="15/07/2026"
                       label="Date" />
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

  testWidgets('shows the server-localized date', (tester) async {
    await renderInput(tester);

    expect(find.text('15/07/2026'), findsOneWidget);
    expect(find.byIcon(Icons.calendar_today_outlined), findsOneWidget);
  });

  testWidgets('picks and dispatches an ISO date', (tester) async {
    final (_, server) = await renderInput(tester);

    await tester.tap(find.text('15/07/2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('20').last);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'validate',
        'transaction%5Bspent_at%5D=2026-07-20&_target=transaction%5Bspent_at%5D',
      ),
    );
  });
}
