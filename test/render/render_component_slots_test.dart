import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('handles live components', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": {
          "0": {
            "s": ["Hello"]
          },
          "s": ["<Text>", "</Text>"],
          "r": 1
        },
        "s": ["<Container>", "</Container>"],
        "r": 1
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['Hello']);
  });
}
