import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../test_helpers.dart';

void main() {
  testWidgets(
    'logical canvas keeps its ratio and shrinks long text at phone width',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            '''
      <ScaledBox width="966" height="1466" borderRadius="48">
        <Stack><Positioned top="100" left="150" width="600" height="500">
          <FittedBox><Text style="fontSize: 500">図書館で本を読むことが好きです</Text></FittedBox>
        </Positioned></Stack>
      </ScaledBox>''',
          ],
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('図書館で本を読むことが好きです'), findsOneWidget);
      final ratio = tester.widget<AspectRatio>(find.byType(AspectRatio).first);
      expect(ratio.aspectRatio, 966 / 1466);
      expect(find.byType(FittedBox), findsNWidgets(2));
    },
  );
}
