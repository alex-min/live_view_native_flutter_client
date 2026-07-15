import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('decodes HTML entities in dynamic text', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Text>', '</Text>'],
        '0': 'S&#39;inscrire'
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstText(), "S'inscrire");
  });

  testWidgets('decodes mixed static and dynamic text with entities',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Text>Create an account: ', '</Text>'],
        '0': 'S&#39;inscrire'
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstText(), "Create an account: S'inscrire");
  });
}
