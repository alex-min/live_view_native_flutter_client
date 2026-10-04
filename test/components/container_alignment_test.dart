import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_container.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('container centers its child when alignment is center', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        // the Row gives the container loose constraints, like the header
        // row of the vocabulary page where the round add button lives
        's': [
          '''
          <Row>
            <Container width="100" height="100" alignment="center">
              <Text>+</Text>
            </Container>
          </Row>
          ''',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final container = tester.getRect(find.byType(LiveContainer).first);
    expect(container.width, 100);
    expect(container.height, 100);

    final text = tester.getRect(find.text('+'));
    // a centered child keeps its intrinsic size; a null alignment stretches
    // it to fill the container
    expect(text.width, lessThan(50));
    expect(text.height, lessThan(50));
    expect(text.center, container.center);
  });
}
