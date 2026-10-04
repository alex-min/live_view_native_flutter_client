import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'a compact app bar pads the body below the status bar once chrome settles',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final view = LiveView();
      view.catchExceptions = false;
      view.throttleSpammyCalls = false;
      await tester.pumpWidget(view.rootView);

      final (widgets, rootState) =
          LiveViewUiParser(
            html: [
              '<flutter><AppBar toolbarHeight="0" primary="false" />'
                  '<viewBody><Text>Tab page</Text></viewBody></flutter>',
            ],
            htmlVariables: const {},
            liveView: view,
            urlPath: '/dashboard',
            viewType: ViewType.cached,
          ).parse();

      view.router.updatePage(
        url: '/dashboard',
        widget: widgets,
        rootState: rootState,
      );

      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24);
      await tester.pumpAndSettle();

      // the hidden app bar does not cover the status bar, so the body pads
      // itself below it
      expect(tester.getTopLeft(find.text('Tab page')).dy, 24);
    },
  );

  testWidgets(
    'a compact app bar reserves the status bar inset once navigation chrome loads',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final view = LiveView();
      view.catchExceptions = false;
      view.throttleSpammyCalls = false;
      await tester.pumpWidget(view.rootView);

      const body = '''
<flutter extendBodyBehindAppBar="true">
  <AppBar toolbarHeight="[[flutterState key=0]]" primary="false" />
  <viewBody><Text>Cached page</Text></viewBody>
</flutter>
''';

      final (widgets, rootState) =
          LiveViewUiParser(
            html: [body],
            htmlVariables: {'0': '0'},
            liveView: view,
            urlPath: '/accounts',
            viewType: ViewType.cached,
          ).parse();

      view.router.updatePage(
        url: '/accounts',
        widget: widgets,
        rootState: rootState,
      );

      addTearDown(tester.view.reset);
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(top: 24);
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('main_app_bar')), findsNothing);
      expect(tester.getTopLeft(find.text('Cached page')).dy, 24);

      tester.view.physicalSize = const Size(800, 1000);
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('main_app_bar')), findsNothing);
      expect(tester.getTopLeft(find.text('Cached page')).dy, 24);
    },
  );

  testWidgets(
    'the top bar is hidden on small screens when a bottom navigation bar is shown',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final view = LiveView();
      view.catchExceptions = false;
      // Resizing fires window resize events; unthrottled they leave no
      // pending timers behind for the test framework.
      view.throttleSpammyCalls = false;
      await tester.pumpWidget(view.rootView);

      const body = '''
<csrf-token value="csrf"></csrf-token>
<AppBar>
  <title>
    <Text>StartupKit</Text>
  </title>
</AppBar>
<BottomAppBar padding="0">
  <BottomNavigationBar initialValue="0">
    <BottomNavigationBarItem live-patch="/" icon="home" label="Home" />
    <BottomNavigationBarItem live-patch="/users/settings" icon="settings" label="Settings" />
  </BottomNavigationBar>
</BottomAppBar>
<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main>
  <viewBody>
    <Center>
      <Column>
        <Text>Welcome</Text>
      </Column>
    </Center>
  </viewBody>
</div>
''';

      final (widgets, rootState) =
          LiveViewUiParser(
            html: [body],
            htmlVariables: {},
            liveView: view,
            urlPath: '/',
            viewType: ViewType.liveView,
          ).parse();

      view.router.updatePage(url: '/', widget: widgets, rootState: rootState);

      addTearDown(tester.view.reset);

      // Small screen: the bottom bar shows and the top bar is hidden.
      tester.view.physicalSize = const Size(500, 1000);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpAndSettle();

      expect(find.text('StartupKit'), findsNothing);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Wider screen: the top bar comes back and the bottom bar disappears.
      tester.view.physicalSize = const Size(800, 1000);
      await tester.pumpAndSettle();

      expect(find.text('StartupKit'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Settings'), findsNothing);
    },
  );
}
