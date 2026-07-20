import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('does not flash missing viewBody when Scaffold wraps it', (
    tester,
  ) async {
    var view =
        LiveView()..handleRenderedMessage({
          's': [
            '''
<flutter>
  <csrf-token value="token"></csrf-token>
  <div data-phx-session="session" data-phx-static="static">
    <Scaffold>
      <AppBar>
        <title><Text>StartupKit</Text></title>
      </AppBar>
      <viewBody>
        <Center>
          <Text>Welcome home</Text>
        </Center>
      </viewBody>
    </Scaffold>
  </div>
</flutter>
''',
          ],
        });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstText(), isNot(contains('Unable to find any')));
    expect(find.text('Welcome home'), findsOneWidget);
  });
}
