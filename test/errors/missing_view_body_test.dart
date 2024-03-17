import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('Button with inner text are rendered as a Text element',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<flutter><Text>hello</Text><Text>world</Text></flutter>'],
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(
        find.firstText(), 'Unable to find any <viewBody> component on url /');
  });
}
