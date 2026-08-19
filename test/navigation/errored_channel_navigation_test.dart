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

  testWidgets('ignores messages buffered by the channel for the prior page', (
    tester,
  ) async {
    final (view, server) = await connect(
      LiveView(),
      rendered: {
        's': ['<viewBody><Text>Original page</Text></viewBody>'],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final priorChannel = server.lastChannel!;
    await view.livePatch('/transactions/1/edit');
    view.handleMessage(
      Message(event: PhoenixChannelEvent('phx_close')),
      sourceChannel: priorChannel,
    );
    await tester.pump();

    final currentChannel = server.lastChannel!;
    expect(currentChannel, isNot(same(priorChannel)));
    view.handleRenderedMessage({
      's': ['<viewBody><Text>Transaction form</Text></viewBody>'],
    });
    await tester.pumpAndSettle();

    view.handleMessage(
      Message(
        event: PhoenixChannelEvent.custom('live_redirect'),
        payload: {'to': '/accounts/1/transactions', 'kind': 'push'},
      ),
      sourceChannel: priorChannel,
    );
    view.handleMessage(
      Message(
        event: PhoenixChannelEvent.custom('diff'),
        payload: {'0': 'Stale transaction list'},
      ),
      sourceChannel: priorChannel,
    );
    await tester.pumpAndSettle();

    expect(view.currentUrl, '/transactions/1/edit');
    expect(find.text('Transaction form'), findsOneWidget);
    expect(find.text('Stale transaction list'), findsNothing);
    expect(server.lastChannel, same(currentChannel));
  });
}
