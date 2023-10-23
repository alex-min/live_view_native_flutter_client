import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('phx-onload', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': ['<Text phx-onload="backend_event">The counter is ', '</Text>'],
      '0': 2
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions,
        [liveEvents.join, liveEvents.event('backend_event')]);

    view.handleDiffMessage({'0': 5});
    await tester.pumpAndSettle();

    expect(server.lastChannelActions,
        [liveEvents.join, liveEvents.event('backend_event')],
        reason: 'changing the view should not retrigger the event');
  });
}
