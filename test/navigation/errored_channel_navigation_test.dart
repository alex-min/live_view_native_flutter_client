import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('drops events and dead-navigates from an errored channel', (
    tester,
  ) async {
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': ['<viewBody><Text>Current page</Text></viewBody>'],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final erroredChannel = server.lastChannel!;
    erroredChannel.currentState = PhoenixChannelState.errored;

    expect(
      view.sendEvent(
        ExecLiveEvent(type: 'phx-click', name: 'load_page', value: {}),
      ),
      isFalse,
    );

    await view.livePatch('/target');
    await tester.pumpAndSettle();

    expect(
      server.httpRequestsMade.any(
        (request) => request.method == 'GET' && request.url.path == '/target',
      ),
      isTrue,
    );
    expect(erroredChannel.actions, [liveEvents.join]);
    expect(view.currentUrl, '/target');
  });
}
