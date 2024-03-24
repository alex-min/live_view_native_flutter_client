import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('The main data-phx-main div does not break the render',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<div data-phx-main><Text>works</Text></div>'],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.firstText(), 'works');
  });
}
