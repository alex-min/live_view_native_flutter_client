import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  testWidgets('filled button with type="submit" submits its form', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Form phx-change="validate" phx-submit="save">
            <TextField name="user[email]" />
            <FilledButton type="submit">Save</FilledButton>
          </Form>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'person@example.com');
    await tester.pump();
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final action = server.lastChannelAction!;
    expect(action.eventName, 'event');
    expect(action.payload?['type'], 'form');
    expect(action.payload?['event'], 'save');
    expect(
      action.payload?['value'],
      contains('user%5Bemail%5D'), // user[email]
      reason:
          'The submit must carry the form field values, got: ${action.payload?['value']}',
    );
  });

  testWidgets('filled button without type does not submit its form', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Form phx-change="validate" phx-submit="save">
            <TextField name="user[email]" />
            <FilledButton>Just a button</FilledButton>
          </Form>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Just a button'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(server.lastChannelAction?.payload?['event'], isNot('save'));
  });
}
