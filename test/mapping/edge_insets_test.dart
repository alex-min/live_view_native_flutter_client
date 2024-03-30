import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';

void main() {
  test('common cases', () {
    expect(getEdgeInsets(""), null);
    expect(getEdgeInsets("10"), const EdgeInsets.all(10));
    expect(
      getEdgeInsets("10 0"),
      const EdgeInsets.symmetric(
        vertical: 10,
        horizontal: 0,
      ),
    );
    expect(
      getEdgeInsets("10 0 5"),
      const EdgeInsets.only(
        top: 10,
        right: 0,
        bottom: 5,
        left: 0,
      ),
    );
    expect(
      getEdgeInsets("10 2 5"),
      const EdgeInsets.only(
        top: 10,
        right: 2,
        bottom: 5,
        left: 2,
      ),
    );
    expect(
      getEdgeInsets("10 1 5 8"),
      const EdgeInsets.only(
        top: 10,
        right: 1,
        bottom: 5,
        left: 8,
      ),
    );
  });
}
