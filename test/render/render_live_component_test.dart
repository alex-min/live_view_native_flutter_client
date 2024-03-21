import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('handles live components', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": 1,
        "s": ["<viewBody><Container>", "</Container></viewBody>"],
        "c": {
          "1": {
            "0": "20",
            "1": 2,
            "s": ["<Container><Text>A: ", "</Text>", "</Container>"]
          },
          "2": {
            "0": "10",
            "s": ["<Text>B: ", "</Text>"]
          }
        }
      });

    await tester.runLiveView(view);

    expect(find.allTexts(), ['A: 20', 'B: 10']);
  });

  testWidgets('handles a new live component', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": 1,
        "s": ["<Container>", "</Container>"],
        "c": {
          "1": {
            "0": "world",
            "1": "",
            "s": ["<Container><Text>Hello ", "</Text>", "</Container>"]
          }
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.allTexts(), ['Hello world']);

    view.handleDiffMessage({
      "0": 1,
      "c": {
        "1": {
          "0": "mars",
          "1": {
            "s": ["<Text>New Home</Text>"]
          }
        }
      }
    });
    await tester.pump();

    expect(find.allTexts(), ['Hello mars', 'New Home']);
  });

  testWidgets('handles remove a live component', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": 1,
        "s": ["<Container>", "</Container>"],
        "c": {
          "1": {
            "0": "world",
            "1": {
              "s": ["<Text>New Home</Text>"]
            },
            "s": ["<Container><Text>Hello ", "</Text>", "</Container>"]
          }
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    expect(find.allTexts(), ['Hello world', 'New Home']);

    view.handleDiffMessage({
      "0": 1,
      "c": {
        "1": {"0": "mars", "1": ""}
      }
    });
    await tester.pump();

    expect(find.allTexts(), ['Hello mars']);
  });
}
