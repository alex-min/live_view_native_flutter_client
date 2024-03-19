import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('handles variable inside text', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          '<Text>the first counter is (',
          ') and the second one is (',
          ')</Text>'
        ],
        '0': 10,
        '1': 12
      });

    await tester.runLiveView(view);
    expect(find.firstText(),
        'the first counter is (10) and the second one is (12)');
  });
}
