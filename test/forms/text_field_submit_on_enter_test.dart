import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets(
    'submitOnEnter dispatches the form submit event when Enter is pressed',
    (tester) async {
      var (view, server) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
              <Form phx-submit="send">
                <TextField name="body" submitOnEnter="true" />
              </Form>
            """,
          ],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      await tester.showKeyboard(find.byType(TextFormField));
      await tester.enterText(find.byType(TextFormField), 'hello');
      await tester.pumpAndSettle();

      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(
        server.lastChannelAction,
        liveEvents.phxFormValidate('send', 'body=hello&_target=body'),
      );
    },
  );

  testWidgets('pressing Enter does not submit without submitOnEnter', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
            <Form phx-submit="send">
              <TextField name="body" />
            </Form>
          """,
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.showKeyboard(find.byType(TextFormField));
    await tester.enterText(find.byType(TextFormField), 'hello');
    await tester.pumpAndSettle();

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      server.lastChannelActions?.where(
        (a) => a.eventName == 'event' && a.payload?['event'] == 'send',
      ),
      isEmpty,
    );
  });
}
