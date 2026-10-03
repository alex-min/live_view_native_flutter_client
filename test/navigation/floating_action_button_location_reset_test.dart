import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

String page(String title, {required String? location}) => '''
<flutter extendBodyBehindAppBar="true">
  <AppBar toolbarHeight="0" primary="false" />
  <viewBody ${location != null ? 'floatingActionButtonLocation="$location"' : ''}>
    <Text>$title</Text>
  </viewBody>
  <FloatingActionButton live-patch="/transactions/new" shape="CircleBorder">
    <Icon name="add" />
  </FloatingActionButton>
  <BottomAppBar elevation="10" padding="0" shape="CircularNotchedRectangle" clipBehavior="antiAlias">
    <BottomNavigationBar initialValue="1" showUnselectedLabel="true" elevation="0">
      <BottomNavigationBarItem live-patch="/dashboard" icon="home" label="Home" />
      <BottomNavigationBarItem live-patch="/accounts" icon="account_balance" label="Accounts" />
    </BottomNavigationBar>
  </BottomAppBar>
</flutter>
''';

Future<void> navigateTo(
  LiveView view,
  WidgetTester tester,
  String url,
  String html,
) async {
  await view.livePatch(url);
  await tester.pump();
  view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
  view.handleRenderedMessage({
    's': [html],
  });
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'the FAB location of the previous page does not leak into a page without one',
    (tester) async {
      tester.setScreenSize(const Size(1280, 720));

      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [page('Form page', location: 'centerDockedWithoutBar')],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();

      var scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.floatingActionButtonLocation.toString(),
        contains('CenterDockedWithoutBar'),
      );

      await navigateTo(
        view,
        tester,
        '/accounts/1/transactions',
        page('Tx page', location: null),
      );

      // Without the attribute the scaffold default applies; the form page's
      // "docked without bar" offset would float the FAB above the bottom bar.
      scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.floatingActionButtonLocation, isNull);
      // The scaffold default (endFloat) still overlaps the bottom bar's band.
      final fabCenter = tester.getCenter(find.byType(FloatingActionButton));
      expect(fabCenter.dy, greaterThan(560));
    },
  );

  testWidgets('an explicit location on the destination page still wins', (
    tester,
  ) async {
    // Narrow screen: BottomNavigationBar collapses at wider breakpoints and
    // takes the BottomAppBar band with it, so the bar must exist here.
    tester.setScreenSize(const Size(400, 720));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [page('Form page', location: 'centerDockedWithoutBar')],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await navigateTo(
      view,
      tester,
      '/accounts',
      page('Accounts page', location: 'centerDocked'),
    );

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(
      scaffold.floatingActionButtonLocation,
      FloatingActionButtonLocation.centerDocked,
    );
    final barTop = tester.getRect(find.byType(BottomAppBar)).top;
    final fabCenter = tester.getCenter(find.byType(FloatingActionButton));
    expect((fabCenter.dy - barTop).abs(), lessThan(30));
  });
}
