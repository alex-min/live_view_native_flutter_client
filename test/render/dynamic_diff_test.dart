import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('Dynamic diffs are working', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<viewBody><Container>', '</Container>', '</viewBody>'],
        '1': {
          's': ['<Text>something</Text>'],
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {
        's': ['<Text', 'my-property="1">', '</Text>'],
        'd': [
          ['kind="info"', "hello"],
          ['kind="error"', "world"],
        ]
      },
    });

    await tester.pumpAndSettle();

    expect(find.allTexts(), ['hello', 'world', 'something']);

    view.handleDiffMessage({
      '0': {'d': []}
    });

    await tester.pumpAndSettle();

    expect(find.allTexts(), ['something']);
  });
}
