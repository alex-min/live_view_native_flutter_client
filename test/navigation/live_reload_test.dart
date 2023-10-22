import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('live reloads the page', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
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
        <link flutter-click="go_back">go back</link>
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
}
