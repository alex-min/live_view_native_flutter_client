import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('keeps focus when validation reparses the form', (tester) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<flutter><viewBody>', '</viewBody></flutter>'],
        '0': {
          's': [
            '<Column><Card><Container><Form phx-change="validate">'
                '<TextField name="email" errors="',
            '" /></Form></Container></Card></Column>',
          ],
          '0': '[]',
        },
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final field = find.byType(TextField);
    await tester.tap(field);
    await tester.enterText(field, 'a');
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );

    view.handleDiffMessage({
      '0': {'0': '[{"message":"must be an email","options":{}}]'},
    });
    await tester.pumpAndSettle();

    expect(field, findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    expect(tester.widget<TextField>(field).controller?.text, 'a');
    expect(find.text('must be an email'), findsOneWidget);
  });
}
