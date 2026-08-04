import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';
import 'package:liveview_flutter/live_view/ui/errors/parsing_error_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('diffs are not applied to widgets from previous pages', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      onRequest:
          (request) => textFlutterHttpResponse("""<flutter>
              $xmlCsrf
              <viewBody><link live-patch="/page-b"><Text>go</Text></link></viewBody>
            </flutter>"""),
    );

    await tester.runLiveView(view);

    // Page A: a section whose dynamics are attribute fragments.
    view.handleRenderedMessage({
      's': [
        '<viewBody><link live-patch="/page-b"><Text>go</Text></link>',
        '</viewBody>',
      ],
      '0': {
        's': ['<CurrencyAmount', '', '', '></CurrencyAmount>'],
        '0': ' text="0 €"',
        '1': ' color="@theme.colorScheme.primary"',
        '2': ' style="textTheme: headlineMedium"',
      },
    });
    await tester.pumpAndSettle();
    expect(find.byType(ParsingErrorView, skipOffstage: false), findsNothing);

    // Navigate to page B; page A stays mounted in the navigation stack.
    // The server closes the channel and the client re-joins on the patched
    // url (mirrors the phx_close handling in go_back_test).
    await tester.tap(find.byType(LiveLink));
    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    expect(view.currentUrl, '/page-b');

    view.handleRenderedMessage({
      's': ['<viewBody>', '</viewBody>'],
      '0': {
        's': ['<Text>picker ', '</Text>'],
        '0': 'closed',
      },
    });
    await tester.pumpAndSettle();
    expect(find.text('picker closed'), findsOneWidget);

    // A full section diff for page B (new statics and dynamics) at the same
    // top-level key as page A's section.
    view.handleDiffMessage({
      '0': {
        's': ['<Text>picker ', '</Text>'],
        '0': 'open',
        '1': 'extra',
      },
    });
    await tester.pumpAndSettle();
    expect(find.text('picker open'), findsOneWidget);

    // A partial diff with a raw value at a key which holds an attribute
    // fragment in page A's section. If page A's stale widget applied it, the
    // merge would produce a bare placeholder between attributes and the
    // re-render would fail to parse.
    view.handleDiffMessage({
      '0': {'1': '@theme.colorScheme.onSurfaceVariant'},
    });
    await tester.pumpAndSettle();

    expect(find.text('picker open'), findsOneWidget);
    expect(find.byType(ParsingErrorView, skipOffstage: false), findsNothing);
  });
}
