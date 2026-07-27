import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

String? fieldValue() =>
    (find.byType(TextField).evaluate().first.widget as TextField)
        .controller
        ?.text;

main() async {
  testWidgets('initial value cannot change from the server', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<TextField ', '/>'],
        '0': 'initialValue="initialValue"',
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(fieldValue(), 'initialValue');

    view.handleDiffMessage({'0': 'initialValue="new value"'});
    await tester.pumpAndSettle();

    expect(fieldValue(), 'initialValue');
  });

  testWidgets('handles form change', (tester) async {
    var (view, server) = await connect(LiveView());
    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """
          <Form phx-change="my_validate_event">
            <TextField name="myfield" />
          </Form>
        """,
      ],
    });
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'typing');

    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'my_validate_event',
        'myfield=typing&_target=myfield',
      ),
    );
  });

  testWidgets('interpolates error message variables', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<TextField name="password" errors="', '" />'],
        '0':
            '[{"message":"should be at least %{count} characters","options":{"count":8}}]',
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('should be at least 8 characters'), findsOneWidget);
  });
}
