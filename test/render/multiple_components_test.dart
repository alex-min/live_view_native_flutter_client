import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('multiple dynamic components on the same rendering pass',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<flutter><viewBody>', '', '</viewBody></flutter>'],
        '0': {
          's': ['<Text>hello</Text>'],
        },
        '1': {
          's': ['<Text>world</Text>'],
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['hello', 'world']);
  });

  testWidgets('multiple components on the same rendering pass', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<flutter><viewBody>', '</viewBody></flutter>'],
        '0': {
          's': ['<Text>hello</Text><Text>world</Text>'],
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['hello', 'world']);
  });
}
