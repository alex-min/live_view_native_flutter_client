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

  testWidgets('handles update a different live component', (tester) async {
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

    view.handleDiffMessage({
      "0": 1,
      "c": {
        "1": {
          "0": "world",
        }
      }
    });
    await tester.pump();

    expect(find.allTexts(), ['Hello world', 'New Home']);
  });

  testWidgets('handles a nested update inside a dynamic component',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": 1,
        "s": ["<Container>", "</Container>"],
        "c": {
          "1": {
            "0": "world",
            "1": {
              "0": "1",
              "1": "2",
              "s": ["<Text>Counter: ", " - ", "</Text>"]
            },
            "s": ["<Container><Text>Hello ", "</Text>", "</Container>"]
          }
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['Hello world', 'Counter: 1 - 2']);

    view.handleDiffMessage({
      "0": 1,
      "c": {
        "1": {
          "0": "mars",
          "1": {"0": "2", "1": "3"}
        }
      }
    });
    await tester.pump();

    expect(find.allTexts(), ['Hello mars', 'Counter: 2 - 3']);
  });

  testWidgets('handles a nested live_component update', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": 1,
        "s": ["<Container>", "</Container>"],
        "c": {
          "1": {
            "0": "world",
            "1": {
              "0": "1",
              "1": "2",
              "s": ["<Text>Counter1: ", " - ", "</Text>"]
            },
            "2": 2,
            "s": ["<Container><Text>Hello ", "</Text>", "", "</Container>"]
          },
          "2": {
            "0": {
              "0": "1",
              "1": "2",
              "s": ["<Text>Counter2: ", " - ", "</Text>"]
            },
            "s": ["<Container>", "</Container>"]
          }
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), [
      'Hello world',
      'Counter1: 1 - 2',
      'Counter2: 1 - 2',
    ]);

    view.handleDiffMessage({
      "0": 1,
      "c": {
        "1": {
          "0": "mars",
          "1": {"0": "2", "1": "3"},
          "2": 2
        },
        "2": {
          "0": {"0": "2", "1": "3"}
        }
      }
    });
    await tester.pump();

    expect(find.allTexts(), [
      'Hello mars',
      'Counter1: 2 - 3',
      'Counter2: 2 - 3',
    ]);
  });

  testWidgets('handles siblings components', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": {
          "0": {
            "0": {
              "0": {
                "s": ["<Text>Text A</Text>"]
              },
              "s": ["<Container>", "</Container>"],
              "r": 1
            },
            "s": ["", ""]
          },
          "s": ["<Container>", "</Container>"],
          "r": 1
        },
        "1": {
          "0": {
            "0": {
              "0": {
                "s": ["<Text>Text B</Text>"]
              },
              "s": ["<Container>", "</Container>"],
              "r": 1
            },
            "1": {
              "0": {
                "s": ["<Text>Text C</Text>"]
              },
              "s": ["<Container>", "</Container>"],
              "r": 1
            },
            "s": ["", "<Container padding=\"10\"></Container>", ""]
          },
          "s": ["<Container>", "</Container>"],
          "r": 1
        },
        "s": ["<Container>", "", "</Container>"],
        "r": 1
      });

    await tester.runLiveView(view);

    expect(find.allTexts(), ['Text A', 'Text B', 'Text C']);
  });

  testWidgets('handles siblings without attributes components', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": {
          "0": {
            "s": ["<Text>A</Text>"],
            "r": 1
          },
          "1": {
            "s": ["<Text>B</Text>"],
            "r": 1
          },
          "2": {
            "s": ["<Text>C</Text>"],
            "r": 1
          },
          "s": ["", "", "", ""]
        },
        "s": ["<Container>", "</Container>"],
        "r": 1
      });

    await tester.runLiveView(view);

    expect(find.allTexts(), ['A', 'B', 'C']);
  });

  testWidgets('handles dynamics with components', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        "0": {
          "d": [
            ["Text", "A"],
            ["Text", "B"],
            ["Text", "C"],
          ],
          "s": ["<Text>", " ", "</Text>"],
          "r": 1
        },
        "s": ["<Container>", "</Container>"],
        "r": 1
      });

    await tester.runLiveView(view);

    expect(find.allTexts(), ['Text A', 'Text B', 'Text C']);
  });
}
