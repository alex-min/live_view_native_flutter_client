import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('handles dynamic attributes', (tester) async {
    var view = LiveView(onReload: () => {})
      ..handleRenderedMessage({
        's': ['<TextField ', '', '></TextField>'],
        '0': 'name="myfield"',
        '1': 'value="content"',
      });

    await tester.runLiveView(view);

    var field = find.firstOf<FormBuilderTextField>();
    expect(field.name, 'myfield');
    expect(field.initialValue, 'content');
    expect(field.value, 'content');

    view.handleDiffMessage({
      '0': 'name="new name"',
      '1': 'value="new content"',
    });
    await tester.pump();

    field = find.firstOf<FormBuilderTextField>();
    expect(field.name, 'new name');
    expect(field.value, 'new content');
  });
}
