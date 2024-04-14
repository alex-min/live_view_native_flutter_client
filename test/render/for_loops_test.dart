import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';

import '../test_helpers.dart';

main() async {
  test('works with components', () {
    expect(
        expandVariables({
          '0': 1,
          'c': {
            '1': {
              "0": "world",
              "1": {
                "s": ["<Text>", "</Text>"]
              },
            }
          }
        }),
        {
          '0': {
            "0": "world",
            "1": {
              "s": ["<Text>", "</Text>"]
            },
          }
        });
  });

  test('works with nested components', () {
    expect(
        expandVariables({
          '0': 1,
          'c': {
            '1': {"0": "world", "2": 2},
            '2': {
              "s": ["<Text>hello</Text>"]
            },
          }
        }),
        {
          '0': {
            "0": "world",
            "2": {
              "s": ["<Text>hello</Text>"]
            }
          }
        });
  });

  test('works when empty', () {
    expect(
        expandVariables({
          '0': {'d': []}
        }),
        {
          '0': {'d': []}
        });
  });

  test('expand variables', () {
    expect(
        expandVariables({
          '0': {
            'd': [
              [0],
              [1],
              [2]
            ]
          }
        }),
        {
          '0': {
            'd': [
              [0],
              [1],
              [2]
            ],
            '0': {'0': 0},
            '1': {'0': 1},
            '2': {'0': 2},
          },
        });
  });

  test('expand templates', () {
    expect(
        expandVariables({
          '0': {
            's': ['<Text>my text is', '<Text>', ''],
            'p': {
              '0': ['<Text>my second test is', '</Text>']
            },
            'd': [
              [
                0,
                {
                  "s": 0,
                  "d": [
                    [0],
                    [1],
                    [2]
                  ]
                }
              ]
            ]
          }
        }),
        {
          '0': {
            's': ['<Text>my text is', '<Text>', ''],
            'p': {
              '0': ['<Text>my second test is', '</Text>']
            },
            'd': [
              [
                0,
                {
                  's': 0,
                  'd': [
                    [0],
                    [1],
                    [2]
                  ]
                }
              ]
            ],
            '0': {
              '0': 0,
              '1': {
                's': ['<Text>my second test is', '</Text>'],
                'd': [
                  [0],
                  [1],
                  [2]
                ],
                '0': {'0': 0},
                '1': {'0': 1},
                '2': {'0': 2}
              }
            }
          }
        });
  });

  testWidgets('for with templates', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Container>', '</Container>'],
        '0': {
          's': ['<Text>my text is ', '</Text>', '', ''],
          'p': {
            '0': ['<Text>my second text is ', '</Text>']
          },
          'd': [
            [
              "first text",
              {
                "s": 0,
                "d": [
                  ["hello"],
                ]
              },
              {
                "s": 0,
                "d": [
                  ["world"],
                ]
              },
            ]
          ]
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), [
      'my text is first text',
      'my second text is hello',
      'my second text is world'
    ]);
  });

  testWidgets('for comprehensions', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Container>', '</Container>'],
        '0': {
          's': ['<Text>my text is ', '</Text>'],
          'd': [
            [0],
            [1],
            [2],
            [3],
            [4],
            [5],
          ]
        }
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), [
      'my text is 0',
      'my text is 1',
      'my text is 2',
      'my text is 3',
      'my text is 4',
      'my text is 5'
    ]);

    view.handleDiffMessage({
      '0': {
        'd': [
          ['a'],
          ['b'],
          ['c'],
          ['d'],
          ['e'],
          ['f']
        ]
      }
    });
    await tester.pumpAndSettle();

    expect(find.allTexts(), [
      'my text is a',
      'my text is b',
      'my text is c',
      'my text is d',
      'my text is e',
      'my text is f'
    ]);
  });
}
