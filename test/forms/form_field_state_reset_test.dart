import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

String? fieldValue() =>
    (find.byType(TextField).evaluate().first.widget as TextField)
        .controller
        ?.text;

main() {
  testWidgets(
    'typed text is dropped when the form is removed from the tree and reopened',
    (tester) async {
      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            """<flutter><viewBody>
              <Form>
                <TextField name="myfield" />
              </Form>
            </viewBody></flutter>""",
          ],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'stale text');
      await tester.pumpAndSettle();
      expect(fieldValue(), 'stale text');

      // The inline form is cancelled: the server re-renders without it.
      view.handleRenderedMessage({
        's': [
          '<flutter><viewBody><Text>form closed</Text></viewBody></flutter>',
        ],
      });
      await tester.pumpAndSettle();

      expect(view.formValuesFor(view.currentUrl)?['myfield'], isNull);

      // Reopening the form must not resurrect the previously typed text.
      view.handleRenderedMessage({
        's': [
          """<flutter><viewBody>
            <Form>
              <TextField name="myfield" initialValue="fresh" />
            </Form>
          </viewBody></flutter>""",
        ],
      });
      await tester.pumpAndSettle();
      // flush the reopened field's deferred initial-state dispatch (a bare
      // pump() does not advance the fake clock, so the zero-delayed timer
      // would stay pending)
      await tester.pump(const Duration(milliseconds: 10));

      expect(fieldValue(), 'fresh');
    },
  );

  testWidgets('typed text survives a server re-render that keeps the form', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter><viewBody>
              <Form phx-change="validate">
                <TextField name="myfield" errors="" />
              </Form>
            </viewBody></flutter>""",
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'kept text');
    await tester.pumpAndSettle();

    // A server response re-renders the page while the form stays open
    // (validation round trip adding errors).
    view.handleRenderedMessage({
      's': [
        """<flutter><viewBody>
            <Form phx-change="validate">
              <TextField name="myfield" errors="[{&quot;message&quot;: &quot;is invalid&quot;}]" />
            </Form>
          </viewBody></flutter>""",
      ],
    });
    await tester.pumpAndSettle();
    // flush the rebuilt field's deferred initial-state dispatch
    await tester.pump(const Duration(milliseconds: 10));

    expect(fieldValue(), 'kept text');
    expect(view.formValuesFor(view.currentUrl)?['myfield'], 'kept text');
  });
}
