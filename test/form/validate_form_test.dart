import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('handles form change', (tester) async {
    var (view, server) = await connect(LiveView());
    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """
          <Form phx-change="my_validate_event">
            <TextField name="myfield" />
          </Form>
        """
      ],
    });
    await tester.pumpAndSettle();

    var field = find.firstOf<TextField>();
    field.controller!.value = const TextEditingValue(text: 'typing');
    expect(
        server.lastChannelAction,
        liveEvents.phxFormValidate(
            'my_validate_event', 'myfield=typing&_target=myfield'));
  });
}
