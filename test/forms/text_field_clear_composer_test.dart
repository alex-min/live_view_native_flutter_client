import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

String? fieldValue() =>
    (find.byType(TextField).evaluate().first.widget as TextField)
        .controller
        ?.text;

void main() {
  testWidgets('clear-composer event empties the field and its stored value', (
    tester,
  ) async {
    var (view, _) = await connect(
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

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();
    expect(fieldValue(), 'hello');

    view.handleDiffMessage({
      'e': [
        [
          'clear-composer',
          {'field': 'body'},
        ],
      ],
    });
    await tester.pumpAndSettle();

    expect(fieldValue(), '');
    expect(view.formValuesFor(view.currentUrl)?['body'], isNull);
  });

  testWidgets('clear-composer on another field leaves this field untouched', (
    tester,
  ) async {
    var (view, _) = await connect(
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

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      'e': [
        [
          'clear-composer',
          {'field': 'other'},
        ],
      ],
    });
    await tester.pumpAndSettle();

    expect(fieldValue(), 'hello');
  });
}
