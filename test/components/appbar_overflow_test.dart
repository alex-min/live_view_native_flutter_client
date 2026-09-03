import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('wide actions do not overflow a narrow app bar', (tester) async {
    final (view, _) = await connect(LiveView());
    tester.setScreenSize(const Size(400, 700));
    await tester.runLiveView(view);

    view.handleRenderedMessage({
      's': [
        '''
        <flutter>
          <AppBar>
            <title><Text>Finance</Text></title>
            <TextButton><Text>A very long account email address</Text></TextButton>
            <TextButton><Text>Log out</Text></TextButton>
            <IconButton icon="menu" />
            <IconButton icon="dark_mode" />
          </AppBar>
          <viewBody><Text>Content</Text></viewBody>
        </flutter>
        ''',
      ],
    });
    await tester.pumpAndSettle();

    expect(find.byType(AppBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
