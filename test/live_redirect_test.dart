import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import 'test_helpers.dart';

void main() {
  Future<(LiveView, FakeLiveSocket)> connectOnAccountsForm(
    WidgetTester tester,
  ) async {
    var (view, socket) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <Text>New account</Text>
          </viewBody>
        </flutter>
      """,
        ],
      },
      url: 'http://localhost:9999/accounts/new',
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    return (view, socket);
  }

  testWidgets('live_redirect channel event live-navigates to the target URL', (
    tester,
  ) async {
    var (view, socket) = await connectOnAccountsForm(tester);

    expect(view.currentUrl, '/accounts/new');

    view.handleMessage(
      Message(
        event: PhoenixChannelEvent.custom('live_redirect'),
        payload: {'to': '/accounts', 'kind': 'push'},
      ),
    );

    await tester.pumpAndSettle();

    // No dead-view reload: the client shows a loading page and waits to
    // rejoin the channel, like a live-patch link.
    expect(
      view.router.pages.map((p) => p.page.name),
      contains('loading;/accounts'),
    );

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    await tester.pump();

    expect(view.currentUrl, '/accounts');
    // The channel is rejoined with a redirect param, not a fresh dead-view GET.
    expect(socket.liveSocket?.navigationLogs.last, {
      'url': null,
      'redirect': 'http://localhost:9999/accounts',
    });
    expect(
      socket.httpRequestsMade.where(
        (r) => r.method == 'GET' && r.url.path == '/accounts',
      ),
      isEmpty,
    );
  });

  testWidgets(
    'live_redirect in an event reply live-navigates to the target URL',
    (tester) async {
      var (view, socket) = await connectOnAccountsForm(tester);

      view.handleMessage(
        Message(
          event: PhoenixChannelEvent.custom('phx_reply'),
          payload: {
            'status': 'ok',
            'response': {
              'live_redirect': {'to': '/accounts', 'kind': 'push'},
            },
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(
        view.router.pages.map((p) => p.page.name),
        contains('loading;/accounts'),
      );

      view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
      await tester.pump();

      expect(view.currentUrl, '/accounts');
      expect(socket.liveSocket?.navigationLogs.last, {
        'url': null,
        'redirect': 'http://localhost:9999/accounts',
      });
      expect(
        socket.httpRequestsMade.where(
          (r) => r.method == 'GET' && r.url.path == '/accounts',
        ),
        isEmpty,
      );
    },
  );
}
