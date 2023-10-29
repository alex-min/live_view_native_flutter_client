import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testGoldens('segmented buttons looks okay', (tester) async {
    await tester.checkScreenshot("""
          <Row>
            <ElevatedButton>hello</ElevatedButton>
          </Row>
        """, 'elevated_button_test.png');
  });

  testWidgets('phx click works', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
          <Row>
            <Container padding="20">
              <ElevatedButton phx-click="my_event" phx-value-count="50">hello</ElevatedButton>
            </Container>
          </Row>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('hello'), warnIfMissed: false);

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({'count': '50'}, eventName: 'my_event'),
    ]);
  });

  testWidgets('type=submit for forms', (tester) async {
    await loadAppFonts();
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        """
            <Form phx-submit="submit_event" phx-change="change_event">
              <TextField initialValue="hello" name="my_field" />
              <ElevatedButton>does nothing</ElevatedButton>
              <ElevatedButton type="submit" name="submit">submit</ElevatedButton>
            </Form>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('does nothing'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [liveEvents.join]);

    await tester.tap(find.text('submit'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      const EventSent('event', {
        'type': 'form',
        'event': 'submit_event',
        'value': 'my_field=hello&_target=submit'
      })
    ]);
  });
}
