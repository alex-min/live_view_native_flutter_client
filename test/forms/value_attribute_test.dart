import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('changing value does not reset the input', (tester) async {
    var view = LiveView()
      ..handleRenderedMessage({
        's': ['<TextField ', '', '></TextField>'],
        '0': 'name="myfield"',
        '1': 'value="content"',
      });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.firstOf<TextFormField>().initialValue, 'content');
    expect((find.firstOf<TextField>()).controller?.text, 'content');

    view.handleDiffMessage({
      '0': 'name="new name"',
      '1': 'value="new content"',
    });
    await tester.pumpAndSettle();

    expect((find.firstOf<TextField>()).controller?.text, 'content');
  });
}
