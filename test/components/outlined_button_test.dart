import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('renders an outlined button', (tester) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<flutter><viewBody><OutlinedButton>Delete</OutlinedButton>'
              '</viewBody></flutter>',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pump();

    expect(find.byType(OutlinedButton), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);
  });
}
