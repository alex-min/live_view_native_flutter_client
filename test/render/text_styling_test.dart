import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('rext styling', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': [
          '<Text style="textTheme: headlineMedium; fontWeight: bold; fontStyle: italic">my text</Text>'
        ],
      });

    await tester.runLiveView(view);

    var text = find.firstOf<Text>();
    expect(
        text.style!.debugLabel,
        [
          '(((englishLike headlineSmall 2021)',
          '.merge((blackMountainView headlineSmall).apply))',
          '.merge(fontWeight FontWeight.w700))',
          '.merge(fontStyle FontStyle.italic)'
        ].join());
  });

  testWidgets('handles dynamic styling', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Text ', '>my test</Text>'],
        '0': 'style="fontWeight: bold"',
      });

    await tester.runLiveView(view);

    var text = find.firstOf<Text>();
    expect(text.style!.toString(),
        'TextStyle(debugLabel: (unknown).merge(fontWeight FontWeight.w700), inherit: true, weight: 700)');
  });
}
