import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_positioned.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('a persistent widget is hoisted, kept across navigation without '
      'rebuilding, and dropped when the page stops declaring it', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [_page('First page', withBubble: true)],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LivePositioned), findsOneWidget);
    final bubbleState = tester.state(find.byType(LivePositioned));

    unawaited(view.livePatch('/second-page'));
    await tester.pump();

    // The loading frame must neither duplicate nor rebuild the bubble.
    expect(find.byType(LivePositioned), findsOneWidget);
    expect(
      tester.state(find.byType(LivePositioned)),
      same(bubbleState),
      reason: 'the loading frame must keep the hoisted bubble instance',
    );

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Second page', withBubble: true)],
    });
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsOneWidget);
    expect(find.byType(LivePositioned), findsOneWidget);
    expect(
      tester.state(find.byType(LivePositioned)),
      same(bubbleState),
      reason: 'the destination page must not rebuild the hoisted bubble',
    );

    // A page without the declaration drops the chrome.
    unawaited(view.livePatch('/third-page'));
    await tester.pump();
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Third page', withBubble: false)],
    });
    await tester.pumpAndSettle();

    expect(find.text('Third page'), findsOneWidget);
    expect(find.byType(LivePositioned), findsNothing);
  });

  testWidgets('a persistent widget inside dynamic content is hoisted too', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    // Mirrors the real server render: the viewBody content lives in a
    // dynamic template entry (the static tree holds a flutterState
    // placeholder), which is where the persistent bubble is declared.
    var view =
        LiveView()..handleRenderedMessage({
          's': [
            '<flutter><viewBody><Stack>[[flutterState key=0]]</Stack></viewBody></flutter>',
          ],
          '0': {
            's': ['<ListView><Text>Home</Text></ListView>${_bubble()}'],
          },
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
      find.byIcon(Icons.chat_bubble),
      findsOneWidget,
      reason:
          'the bubble must render even though the static page tree '
          'only holds a flutterState placeholder',
    );
  });

  testWidgets('a hoisted persistent widget still dispatches live-patch taps', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [_page('First page', withBubble: true)],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.chat_bubble));
    await tester.pumpAndSettle();

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    await tester.pumpAndSettle();

    expect(server.liveSocket?.navigationLogs.last, {
      'url': null,
      'redirect': 'http://localhost:9999/support',
    });
  });

  testWidgets('a persistent widget is kept across replace-mode navigation and '
      'survives a second tap before the arriving page renders', (tester) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [_page('First page', withBubble: true)],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(LivePositioned), findsOneWidget);
    final bubbleState = tester.state(find.byType(LivePositioned));

    // Replace navigation to a second page declaring the bubble,
    // like the bottom navigation bar items do.
    unawaited(view.livePatch('/second-page', replace: true));
    await tester.pump();
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Second page', withBubble: true)],
    });
    await tester.pumpAndSettle();

    expect(find.text('Second page'), findsOneWidget);
    expect(find.byType(LivePositioned), findsOneWidget);
    expect(
      tester.state(find.byType(LivePositioned)),
      same(bubbleState),
      reason: 'replace navigation must not rebuild the hoisted widget',
    );

    // Tap again before the arriving page's body renders: the chrome must
    // survive the interrupted navigation instead of being dropped.
    unawaited(view.livePatch('/third-page', replace: true));
    await tester.pump();
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Third page', withBubble: true)],
    });
    // No pump here: the /third-page body has not rendered yet.
    unawaited(view.livePatch('/fourth-page', replace: true));
    for (
      var attempt = 0;
      attempt < 100 && view.redirectToUrl != '/fourth-page';
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 10));
    }
    expect(view.redirectToUrl, '/fourth-page');
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    view.handleRenderedMessage({
      's': [_page('Fourth page', withBubble: true)],
    });
    await tester.pumpAndSettle();

    expect(find.text('Fourth page'), findsOneWidget);
    expect(find.byType(LivePositioned), findsOneWidget);
    expect(
      tester.state(find.byType(LivePositioned)),
      same(bubbleState),
      reason:
          'an interrupted replace navigation must not drop or rebuild '
          'the hoisted widget',
    );
  });
}

String _page(String title, {required bool withBubble}) => '''
<flutter>
  <viewBody>
    <Stack>
      <ListView>
        <Text>$title</Text>
      </ListView>
      ${withBubble ? _bubble() : ''}
    </Stack>
  </viewBody>
</flutter>
''';

String _bubble() => '''
<Positioned bottom="96" right="16" persistent="true">
  <Container
    width="56"
    height="56"
    alignment="center"
    live-patch="/support"
    decoration="background: #8D63FF; borderRadius: 999"
  >
    <Icon name="chat_bubble" color="#FFFFFF" size="24.0" />
  </Container>
</Positioned>
''';
