import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:phoenix_socket/phoenix_socket.dart';
import 'package:fake_async/fake_async.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('navigate to another page and back', (tester) async {
    var (view, server) = await connect(LiveView(), onRequest: (request) {
      if (request.url.path == '/') {
        return textFlutterHttpResponse("""<flutter>
              $xmlCsrf 
              <viewBody><link live-patch="/second-page"><Text>variable: 0</Text></link></viewBody>
              </flutter>
            """);
      }
      return textFlutterHttpResponse(xmlCsrf);
    });

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

    view.handleRenderedMessage({
      's': ['<Text phx-click="${baseActions.goBack}">go back</Text>']
    });

    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveText));

    await tester.runAsync(() => Future.delayed(const Duration(seconds: 2)));
    expect(server.lastChannelActions,
        [liveEvents.join, liveEvents.phxLeave, liveEvents.phxLeave]);
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    expect(server.lastChannelActions, [liveEvents.join]);

    // we don't have the second page because live patches aren't part of the navigation logs
    expect((server.liveSocket?.navigationLogs), [
      {'url': 'http://localhost:9999/', 'redirect': null},
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
