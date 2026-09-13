import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  testWidgets('form submit includes the entered field values', (tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Form phx-change="validate" phx-submit="save">
            <TextField name="user[email]" />
            <ElevatedButton type="submit">Save</ElevatedButton>
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

  testWidgets('typed values are remembered for form rebuilds', (tester) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Form phx-change="validate" phx-submit="save">
            <TextField name="user[email]" errors="" />
            <ElevatedButton type="submit">Save</ElevatedButton>
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

    // Every keystroke is remembered on the LiveView, so a form rebuilt by a
    // server diff (fresh widget instances) restores what the user typed
    // instead of the stale server-rendered initial values.
    expect(
      view.formValuesFor(view.currentUrl)?['user[email]'],
      'person@example.com',
    );

    // A validate response arrives with errors populated, like the server
    // sends on each keystroke.
    view.handleDiffMessage({
      's': [
        """<flutter>
        <viewBody>
          <Form phx-change="validate" phx-submit="save">
            <TextField name="user[email]" errors="[{&quot;message&quot;: &quot;is invalid&quot;}]" />
            <ElevatedButton type="submit">Save</ElevatedButton>
          </Form>
        </viewBody>
      </flutter>
      """,
      ],
    });
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'person@example.com');
    await tester.pump();
    await tester.tap(find.text('Save'), warnIfMissed: false);
    await tester.pumpAndSettle();

    final action = server.lastChannelAction!;
    expect(action.payload?['event'], 'save');
    expect(
      Uri.parse('?${action.payload?['value']}').queryParameters['user[email]'],
      'person@example.com',
    );
  });
}
