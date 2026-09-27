import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

String showHide(String showId, String hideId) => FlutterExec.encode([
  FlutterExecAction(name: 'show', value: {'to': showId}),
  FlutterExecAction(name: 'hide', value: {'to': hideId}),
]);

const desktopBox = '''
<Container id="desktop-box"
  phx-responsive="%DESKTOP_ACTIONS%"
  phx-responsive-when="window_width &gt;= 768">
  <Text>Desktop content</Text>
</Container>''';

const mobileBox = '''
<Container id="mobile-box"
  phx-responsive="%MOBILE_ACTIONS%"
  phx-responsive-when="window_width &lt; 768">
  <Text>Mobile content</Text>
</Container>''';

String page() => '''
<flutter>
  <viewBody>
    $desktopBox
    $mobileBox
  </viewBody>
</flutter>
'''
    .replaceAll('%DESKTOP_ACTIONS%', showHide('desktop-box', 'mobile-box'))
    .replaceAll('%MOBILE_ACTIONS%', showHide('mobile-box', 'desktop-box'));

main() {
  testWidgets('conditionally hidden widgets are hidden on the first paint', (
    tester,
  ) async {
    tester.setScreenSize(const Size(500, 500));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [page()],
      },
    );

    await tester.runLiveView(view);

    // a single pump: no post-frame timers (phx-responsive onLoad) ran yet
    await tester.pump();

    expect(find.text('Desktop content'), findsNothing);
    expect(find.text('Mobile content'), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Desktop content'), findsNothing);
    expect(find.text('Mobile content'), findsOneWidget);
  });

  testWidgets('the wide-screen widget is hidden on the first paint', (
    tester,
  ) async {
    tester.setScreenSize(const Size(1000, 500));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [page()],
      },
    );

    await tester.runLiveView(view);

    await tester.pump();

    expect(find.text('Desktop content'), findsOneWidget);
    expect(find.text('Mobile content'), findsNothing);

    await tester.pumpAndSettle();

    expect(find.text('Desktop content'), findsOneWidget);
    expect(find.text('Mobile content'), findsNothing);
  });
}
