import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('Text with live-patch navigates on tap', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <viewBody>
              <Text live-patch="/">Home</Text>
            </viewBody>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pump();

    await tester.tap(find.text('Home'), warnIfMissed: false);
    await tester.pump();

    expect(view.router.pages.map((p) => p.page.name), contains('loading;/'));
  });
}
