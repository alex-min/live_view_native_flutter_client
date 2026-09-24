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

      const closeOnlyBody = '''
<csrf-token value="csrf"></csrf-token>
<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main>
  <viewBody floatingActionButtonLocation="centerDockedWithoutBar">
    <Text>Transaction form</Text>
  </viewBody>
  <FloatingActionButton shape="CircleBorder">
    <Icon name="close" />
  </FloatingActionButton>
</div>
''';

      final (widgets, rootState) =
          LiveViewUiParser(
            html: [closeOnlyBody],
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
      final closeButtonCenter = tester.getCenter(button);
      expect(closeButtonCenter.dx, 200);

      const navigationBody = '''
<csrf-token value="csrf"></csrf-token>
<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main>
  <viewBody floatingActionButtonLocation="centerDocked">
    <Text>Accounts</Text>
  </viewBody>
  <FloatingActionButton shape="CircleBorder">
    <Icon name="add" />
  </FloatingActionButton>
  <BottomAppBar padding="0">
    <BottomNavigationBar>
      <BottomNavigationBarItem icon="home" label="Home" />
      <BottomNavigationBarItem icon="account_balance" label="Accounts" />
      <BottomNavigationBarItem icon="swap_vert" label="Transactions" />
      <BottomNavigationBarItem icon="settings" label="Settings" />
    </BottomNavigationBar>
  </BottomAppBar>
</div>
''';

      final (navigationWidgets, navigationRootState) =
          LiveViewUiParser(
            html: [navigationBody],
            htmlVariables: {},
            liveView: view,
            urlPath: '/accounts',
            viewType: ViewType.liveView,
          ).parse();

      view.router.updatePage(
        url: '/accounts',
        widget: navigationWidgets,
        rootState: navigationRootState,
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomAppBar), findsOneWidget);
      final addButtonCenter = tester.getCenter(
        find.byType(FloatingActionButton),
      );
      expect(closeButtonCenter.dy, closeTo(addButtonCenter.dy, 0.1));
    },
  );
}
