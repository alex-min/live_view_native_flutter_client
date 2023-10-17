import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('global margin', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Container margin="10" />'],
      });

    await tester.runLiveView(view);

    expect(find.firstOf<Container>().margin, const EdgeInsets.all(10.0));
  });

  testWidgets('symetric margin', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Container margin="10 20" />'],
      });

    await tester.runLiveView(view);

    expect(
        find.firstOf<Container>().margin,
        const EdgeInsets.symmetric(
          vertical: 10.0,
          horizontal: 20.0,
        ));
  });

  testWidgets('full margin', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<Container margin="10 20 30 40" />'],
      });

    await tester.runLiveView(view);

    expect(
        find.firstOf<Container>().margin,
        const EdgeInsets.only(
          top: 10.0,
          left: 20.0,
          right: 30.0,
          bottom: 40.0,
        ));
  });
}
