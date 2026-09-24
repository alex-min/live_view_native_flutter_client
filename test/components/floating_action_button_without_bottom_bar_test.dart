import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'centers a floating action button without reserving a bottom bar',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final view = LiveView()..catchExceptions = false;
      await tester.pumpWidget(view.rootView);

      const body = '''
<csrf-token value="csrf"></csrf-token>
<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main>
  <viewBody floatingActionButtonLocation="centerFloat">
    <Text>Transaction form</Text>
  </viewBody>
  <FloatingActionButton shape="CircleBorder">
    <Icon name="close" />
  </FloatingActionButton>
</div>
''';

      final (widgets, rootState) =
          LiveViewUiParser(
            html: [body],
            htmlVariables: {},
            liveView: view,
            urlPath: '/transactions/new',
            viewType: ViewType.liveView,
          ).parse();

      view.router.updatePage(
        url: '/transactions/new',
        widget: widgets,
        rootState: rootState,
      );
      await tester.pumpAndSettle();

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold).first);
      expect(scaffold.bottomNavigationBar, isNull);

      final button = find.byType(FloatingActionButton);
      expect(button, findsOneWidget);
      expect(tester.getCenter(button).dx, 200);
      expect(tester.getBottomRight(button).dy, lessThanOrEqualTo(784));
    },
  );
}
