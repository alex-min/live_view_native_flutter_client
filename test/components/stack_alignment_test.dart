import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('stack centers its children when alignment is center', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '''
          <Container height="100" alignment="center">
            <Stack width="200" height="100" alignment="center">
              <Container width="20" height="20" decoration="background: #ff0000" />
            </Stack>
          </Container>
          ''',
        ],
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    final stack = tester.getRect(find.byType(Stack).first);
    final child = tester.getRect(find.byType(Container).at(1));
    // the 20x20 child is centered inside the 200x100 stack
    expect(child.width, 20);
    expect(child.center, stack.center);
  });
}
