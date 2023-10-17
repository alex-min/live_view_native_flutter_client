import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('supports implicit Columns for single child widgets',
      (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          """<Container>
          <Text>hello</Text>
          <Text>world</Text>
        </Container>"""
        ],
      });

    await tester.runLiveView(view);

    find.firstOf<Column>();
    expect(find.allTexts(), ['hello', 'world']);
  });
}
