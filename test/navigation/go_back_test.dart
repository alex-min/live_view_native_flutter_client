import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/socket/message.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('navigate to another page and back', (tester) async {
    var (view, server) = await connect(LiveView());

    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        '<link live-patch="/second-page"><Text>variable: ',
        '</Text></link>'
      ],
      '0': 1
    });

    await tester.pumpAndSettle();
    view.handleDiffMessage({'0': 3});
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LiveLink));

    expect(server.lastChannelActions, [liveEvents.join, liveEvents.phxLeave]);
    view.handleMessage(LiveMessage(event: 'phx_close'));
    expect(server.lastChannelActions, [liveEvents.join]);

    view.handleRenderedMessage({
      's': ['<Text phx-click="${baseActions.goBack}">go back</Text>']
    });

    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveText));

    expect(server.lastChannelActions, [liveEvents.join, liveEvents.phxLeave]);
    view.handleMessage(LiveMessage(event: 'phx_close'));
    expect(server.lastChannelActions, [liveEvents.join]);

    expect((server.navigationLogs), [
      {'url': 'http://localhost:9999/', 'redirect': null},
      {'url': null, 'redirect': 'http://localhost:9999/second-page'},
      {'url': null, 'redirect': 'http://localhost:9999/'},
    ]);

    view.handleRenderedMessage({
      's': ['<link patch="/second-page"><Text>variable: ', '</Text></link>'],
      '0': 1
    });

    await tester.pumpAndSettle();
    expect(find.firstText(), 'variable: 1',
        reason:
            "it resets the state properly and there's no ghost variables change kept from the first view");
  });
}
