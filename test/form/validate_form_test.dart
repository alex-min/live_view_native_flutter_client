import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

class LiveViewMock extends LiveView {
  LiveEvent? lastEvent;
  LiveViewMock() : super(onReload: () {});

  @override
  sendEvent(LiveEvent event) {
    lastEvent = event;
  }
}

main() async {
  testWidgets('handles form change', (tester) async {
    var view = LiveViewMock()
      ..handleRenderedMessage({
        's': [
          """
          <Form phx-change="my_validate_event">
            <TextField name="myfield" />
          </Form>
        """
        ],
      });

    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      return Scaffold(body: view.rootWidget);
    })));

    var field = find.firstOf<TextField>();
    field.controller!.value = const TextEditingValue(text: 'typing');
    expect(
        view.lastEvent!,
        LiveEvent(
            type: 'form',
            name: 'my_validate_event',
            value: 'myfield=typing&_target=myfield'));
  });
}
