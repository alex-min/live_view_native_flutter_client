import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  // this checks that there's no reloading problem
  // with previous states which arent cleared in state_widget.dart#initState
  testWidgets('whole component update works', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": {
          "0": 'padding="10"',
          "1": {
            "s": ["Hello"]
          },
          "s": ["<Container ", " ><Text>", "</Text></Container>"],
          "r": 1
        },
        "s": ["<Container>", "</Container>"],
        "r": 1
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {'0': 'padding="10"', '1': 'world'}
    });
    await tester.pumpAndSettle();
    expect(find.allTexts(), ['world']);
  });
}
