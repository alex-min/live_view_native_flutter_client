import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() {
  testWidgets('maxLines and overflow attributes reach the Text widget', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Text maxLines="1" overflow="ellipsis">A very long label that truncates</Text>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.data, 'A very long label that truncates');
  });

  testWidgets('text without truncation attributes keeps defaults', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """<flutter>
        <viewBody>
          <Text>wraps freely</Text>
        </viewBody>
      </flutter>
      """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final text = tester.widget<Text>(find.byType(Text));
    expect(text.maxLines, isNull);
    expect(text.overflow, isNull);
  });
}
