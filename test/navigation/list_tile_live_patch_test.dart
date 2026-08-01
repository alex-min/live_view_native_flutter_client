import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('tapping a ListTile with live-patch navigates', (tester) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <ListView>
              <ListTile live-patch="/transactions/42/edit">
                <title><Text>Groceries</Text></title>
                <subtitle><Text>2026-07-31</Text></subtitle>
              </ListTile>
            </ListView>
          </viewBody>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Groceries'));
    await tester.pumpAndSettle();

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    await tester.pumpAndSettle();

    expect(server.liveSocket?.navigationLogs, [
      {'url': 'http://localhost:9999/', 'redirect': null},
      {'url': null, 'redirect': 'http://localhost:9999/transactions/42/edit'},
    ]);
  });
}
