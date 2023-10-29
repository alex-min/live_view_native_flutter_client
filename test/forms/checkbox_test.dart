import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_checkbox.dart';

import '../test_helpers.dart';

bool? checkValue() =>
    (find.byType(Checkbox).evaluate().first.widget as Checkbox).value;

main() async {
  testWidgets('handles checkbox changes', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Form phx-change="my_validate_event">
            <Checkbox name="myfield" />
          </Form>
        """
      ],
    });
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      const EventSent('event', {
        'type': 'form',
        'event': 'my_validate_event',
        'value': 'myfield=on&_target=myfield'
      })
    ]);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(
        server.lastChannelAction,
        const EventSent('event', {
          'type': 'form',
          'event': 'my_validate_event',
          'value': '_target=myfield'
        }),
        reason: 'the checkbox is removed is not checked');
  });

  testWidgets('the initial value is readonly and not changed by server events',
      (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <Form phx-change="my_validate_event">
            <Checkbox """,
        """ />
          </Form>
        """
      ],
      '0': 'checked="true"'
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(checkValue(), true);

    view.handleDiffMessage({'0': 'checked="false"'});

    await tester.pumpAndSettle();

    expect(checkValue(), true,
        reason: 'we do not reset the initial value from server state');
  });

  testWidgets('handles phx-click properly', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': ['<Checkbox phx-click="test" />']
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(checkValue(), false);

    await tester.tap(find.byType(LiveCheckbox));
    await tester.pumpAndSettle();

    expect(checkValue(), true);

    expect(
        server.lastChannelAction, liveEvents.phxClick({}, eventName: 'test'));
  });
}
