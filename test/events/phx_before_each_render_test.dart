import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/socket/message.dart';
import 'package:liveview_flutter/live_view/ui/components/live_link.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('phx-before-each-render', (tester) async {
    // this also checks that we aren't running phx-before-each-render from the previous page when switching
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        '<link phx-before-each-render="${baseActions.switchTheme('light')}" live-patch="/second-page"></link>'
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(view.themeSettings.themeMode, ThemeMode.light,
        reason: "the theme has been set to white by phx-before-each-render");

    await tester.tap(find.byType(LiveLink));
    view.handleMessage(LiveMessage(event: 'phx_close'));

    view.handleRenderedMessage({
      's': [
        '<Text phx-before-each-render="${baseActions.switchTheme('dark')}">my text is ',
        '</Text>',
      ],
      '0': 1
    });

    await tester.pumpAndSettle();

    expect(view.themeSettings.themeMode, ThemeMode.dark,
        reason: "the theme has been set to black by phx-before-each-render");

    await tester
        .runAsync(() => view.themeSettings.setTheme('default', 'light'));

    expect(view.themeSettings.themeMode, ThemeMode.light,
        reason: "we reset the theme manually");

    view.handleDiffMessage({'0': 2});
    await tester.pumpAndSettle();

    expect(view.themeSettings.themeMode, ThemeMode.dark,
        reason:
            "rerendering retriggers phx-before-each-render and thus re-execute the switch theme to black code");
  });
}
