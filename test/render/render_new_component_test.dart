import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('handles a new component', (tester) async {
    var view = LiveView(onReload: () => {})
      ..handleRenderedMessage({
        's': ['<ListView>', '</ListView>'],
        '0': ''
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {
        's': ['<Text>hello world</Text>']
      }
    });
    await tester.pump();

    expect(find.firstText(), 'hello world');
  });

  testWidgets('handles a new component with inside variables', (tester) async {
    var view = LiveView(onReload: () => {})
      ..handleRenderedMessage({
        's': ['<ListView>', '</ListView>'],
        '0': ''
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {
        '0': 1,
        's': ['<Text>the number is ', '</Text>']
      }
    });
    await tester.pump();
    expect(find.firstText(), 'the number is 1');

    view.handleDiffMessage({
      '0': {
        '0': 2,
      }
    });
    await tester.pump();

    expect(find.firstText(), 'the number is 2');
  });

  testWidgets('handles a new component being removed', (tester) async {
    var view = LiveView(onReload: () => {})
      ..handleRenderedMessage({
        's': ['<ListView>', '</ListView>'],
        '0': ''
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    view.handleDiffMessage({
      '0': {
        '0': 1,
        's': ['<Text>hello</Text>']
      }
    });

    await tester.pump();

    expect(find.allTexts(), ['hello']);

    view.handleDiffMessage({'0': ''});
    await tester.pump();

    expect(find.allTexts(), []);
  });
}
