import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('live reloads the page', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': ['<Text>my page</Text>']
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstText(), 'my page');

    view.handleLiveReloadMessage(
        Message(event: PhoenixChannelEvent.custom('assets_change')));

    await tester.pumpAndSettle();

    view.handleRenderedMessage({
      's': [
        """<Container>
        <Text>my page edited</Text>
        <link phx-click="${baseActions.goBack}">go back</link>
        </Container>
      """
      ]
    });

    await tester.pumpAndSettle();

    expect(find.firstText(), 'my page edited');

    expect(
        view.router.pages.map((p) => {'name': p.page.name, 'junk': p.junk}), [
      {'name': 'loading', 'junk': false},
      {'name': '/', 'junk': true},
      {'name': '/', 'junk': false}
    ]);

    // taping go back should do nothing
    // we only reloaded the first page and we should not have any naviation to go back to
    await tester.tap(find.byType(LiveLink));
    await tester.pumpAndSettle();

    expect(find.firstText(), 'my page edited');
    expect(view.router.pages.map((p) => p.page.name), ['/']);
  });

  testWidgets('live reloads after redirection', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': ['<link live-patch="/second-page">link</link>']
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(LiveLink));

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));

    view.handleRenderedMessage({
      's': ['<Text>second page</Text>']
    });

    await tester.pumpAndSettle();

    expect(view.router.pages.last.page.name, '/second-page');

    // we receive this event 3 times from the server
    for (var i = 0; i < 3; i++) {
      view.handleLiveReloadMessage(
          Message(event: PhoenixChannelEvent.custom('assets_change')));
    }

    await tester.pumpAndSettle();

    view.handleRenderedMessage({
      's': ['<Text>second page reloaded</Text>']
    });

    await tester.pumpAndSettle();

    expect(find.firstText(), 'second page reloaded');

    expect(server.httpRequestsMade.map(((t) => t.toString())), [
      // connect
      'GET http://localhost:9999?_lvn%5Bformat%5D=flutter',
      'GET http://localhost:9999/flutter/themes/default/light.json',

      // reconnect after live reload
      'GET http://localhost:9999/second-page?_lvn%5Bformat%5D=flutter',
      'GET http://localhost:9999/flutter/themes/default/light.json'
    ]);

    expect(server.lastChannel?.parameters['redirect'],
        'http://localhost:9999/second-page');
    expect(view.router.pages.last.page.name, '/second-page');
  });
}
