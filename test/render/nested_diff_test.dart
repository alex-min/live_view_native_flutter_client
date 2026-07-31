import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';

void main() {
  group('nestedDiff', () {
    test('extracts the diff at the nested path', () {
      expect(
        nestedDiff(
          {
            '0': {
              '1': {
                's': ['<Text>hi</Text>'],
              },
            },
          },
          ['0', '1'],
        ),
        {
          's': ['<Text>hi</Text>'],
        },
      );
    });

    test('returns an empty diff when the path does not change', () {
      expect(nestedDiff({'0': {}}, ['1']), {});
    });

    test('returns an empty diff when the path holds a leaf value', () {
      // A subtree replaced by a string (or a stale widget from a previous
      // route still listening) must not crash on the non-map diff.
      expect(
        nestedDiff(
          {
            '0': {'1': 'replaced'},
          },
          ['0', '1'],
        ),
        {},
      );
      expect(nestedDiff({'0': ''}, ['0', '1']), {});
    });
  });
}
