import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_toolkit/golden_toolkit.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('phx window resize event', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        '<ElevatedButton phx-window-resize="backend_event">hello</ElevatedButton>'
      ]
    });

    await tester.pumpAndSettle();

    expect(server.lastChannelActions?.last, liveEvents.join);

    tester.setScreenSize(const Size(500, 500));

    await tester.pumpAndSettle();

    expect(server.lastChannelActions?.last, liveEvents.event('backend_event'));
  });

  testWidgets('hides on startup when the condition is met', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """
        <ElevatedButton 
          phx-responsive="${baseActions.hide}"
          phx-responsive-when="window_width > 1">hello</ElevatedButton>
      """
      ]
    });
    await tester.pumpAndSettle();

    expect(find.allTexts(), []);
  });

  testWidgets('when condition', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        """
        <ElevatedButton 
          phx-window-resize="backend_event"
          phx-window-resize-when="window_width > 600">  
        >hello</ElevatedButton>
      """
      ]
    });

    await tester.pumpAndSettle();

    expect(server.lastChannelActions?.last, liveEvents.join);

    tester.setScreenSize(const Size(500, 500));

    await tester.pumpAndSettle();

    expect(server.lastChannelActions?.last, liveEvents.join,
        reason: 'it does not trigger the condition');

    tester.setScreenSize(const Size(700, 700));

    await tester.pumpAndSettle();

    expect(
        server.lastChannelActions?.last,
        const EventSent(
            'event', {'type': 'event', 'event': 'backend_event', 'value': {}}),
        reason: 'the width is enough to trigger the event');
  });

  testGoldens('hide with conditions reverses if the conditions are not met',
      (tester) async {
    loadAppFonts();

    tester.setScreenSize(const Size(400, 400));

    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
        <Container padding="10">
          <Row>
            <ElevatedButton
              phx-window-resize="${baseActions.hide}"
              phx-window-resize-when="window_width > 800"
            >hello</ElevatedButton>
          </Row>
        </Container>
      """
      ]
    });

    await tester.runLiveView(view);

    await tester.pumpAndSettle();
    expect(find.firstText(), "hello");

    tester.setScreenSize(const Size(900, 900));
    await tester.pumpAndSettle();
    tester.setScreenSize(const Size(910, 910));

    await tester.pumpAndSettle();

    expect(find.firstText(), null);

    tester.setScreenSize(const Size(400, 400));

    await tester.pumpAndSettle();
    tester.setScreenSize(const Size(401, 401));
    await tester.pumpAndSettle();

    expect(find.firstText(), "hello");
  });

  testWidgets('shows with conditions reverses if the conditions are not met',
      (tester) async {
    tester.setScreenSize(const Size(400, 400));

    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
        <Container>
          <ElevatedButton 
            phx-window-resize="${baseActions.show}"
            phx-window-resize-when="window_width > 800" 
          >hello</ElevatedButton>
        </Container>
      """
      ]
    });

    await tester.runLiveView(view);

    await tester.pumpAndSettle();
    tester.setScreenSize(const Size(399, 399));
    await tester.pumpAndSettle();
    tester.setScreenSize(const Size(398, 398));
    await tester.pumpAndSettle();

    expect(find.firstText(), null);

    tester.setScreenSize(const Size(900, 900));
    await tester.pumpAndSettle();
    tester.setScreenSize(const Size(910, 910));

    await tester.pumpAndSettle();

    expect(find.firstText(), 'hello');
  });
}
