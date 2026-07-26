import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('bottom navigation bar item live-patch navigates', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <Text>Home page</Text>
          </viewBody>
          <BottomNavigationBar initialValue="0" selectedItemColor="blue-500">
            <BottomNavigationBarItem live-patch="/" icon="home" label="Home" />
            <BottomNavigationBarItem live-patch="/users/settings" icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    view.handleMessage(Message(event: PhoenixChannelEvent('phx_close')));
    await tester.pumpAndSettle();

    expect(server.liveSocket?.navigationLogs, [
      {'url': 'http://localhost:9999/', 'redirect': null},
      {'url': null, 'redirect': 'http://localhost:9999/users/settings'},
    ]);
  });

  testWidgets('bottom navigation bar is hidden on wide screens', (
    tester,
  ) async {
    tester.setScreenSize(const Size(1200, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <Text>Home page</Text>
          </viewBody>
          <BottomNavigationBar selectedItemColor="blue-500">
            <BottomNavigationBarItem icon="home" label="Home" />
            <BottomNavigationBarItem icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);
  });

  testWidgets('bottom navigation bar is visible on narrow screens', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <Text>Home page</Text>
          </viewBody>
          <BottomNavigationBar selectedItemColor="blue-500">
            <BottomNavigationBarItem icon="home" label="Home" />
            <BottomNavigationBarItem icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

  testWidgets(
    'bottom navigation bar visibility updates when the screen is resized',
    (tester) async {
      tester.setScreenSize(const Size(1200, 800));

      var (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            """
          <flutter>
            <viewBody>
              <Text>Home page</Text>
            </viewBody>
            <BottomNavigationBar selectedItemColor="blue-500">
              <BottomNavigationBarItem icon="home" label="Home" />
              <BottomNavigationBarItem icon="settings" label="Settings" />
            </BottomNavigationBar>
          </flutter>
          """,
          ],
        },
      );

      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsNothing);

      tester.setScreenSize(const Size(400, 800));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      tester.setScreenSize(const Size(1200, 800));
      await tester.pumpAndSettle();
      expect(find.byType(BottomNavigationBar), findsNothing);
    },
  );

  testWidgets('bottom navigation bar item phx-click fires event', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody>
            <Text>Home page</Text>
          </viewBody>
          <BottomNavigationBar initialValue="0" selectedItemColor="blue-500">
            <BottomNavigationBarItem phx-click="home_event" icon="home" label="Home" />
            <BottomNavigationBarItem phx-click="settings_event" icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [
      liveEvents.join,
      liveEvents.phxClick({}, eventName: 'settings_event'),
    ]);
  });
}
