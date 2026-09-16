import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:phoenix_socket/phoenix_socket.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('root view can extend behind the bottom navigation bar', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter extendBody="true">
          <viewBody><Text>Home page</Text></viewBody>
          <BottomNavigationBar>
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

    expect(tester.widget<Scaffold>(find.byType(Scaffold)).extendBody, isTrue);
  });

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
            <BottomNavigationBarItem live-patch="/" live-patch-mode="replace" icon="home" label="Home" />
            <BottomNavigationBarItem live-patch="/users/settings" live-patch-mode="replace" icon="settings" label="Settings" />
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

    expect(view.router.pages.map((page) => page.page.name), [
      'loading;/users/settings',
    ]);

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

  testWidgets('bottom navigation bar rebuilds on phx:window:resize event', (
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

    // Change the screen size without pumping, then trigger a window resize
    // event. The bottom nav should rebuild and hide on the wide screen.
    tester.setScreenSize(const Size(1200, 800));
    view.eventHub.fire('phx:window:resize');
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsNothing);

    // And show again when resized back to narrow via the event.
    tester.setScreenSize(const Size(400, 800));
    view.eventHub.fire('phx:window:resize');
    await tester.pumpAndSettle();

    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });

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

  testWidgets('bottom navigation bar can ignore pointer interaction', (
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
          <BottomNavigationBar ignorePointer="true">
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

    final ignoredNavigation = find.ancestor(
      of: find.byType(BottomNavigationBar),
      matching: find.byWidgetPredicate(
        (widget) => widget is IgnorePointer && widget.ignoring,
      ),
    );
    expect(ignoredNavigation, findsOneWidget);
    await tester.tap(find.text('Settings'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(server.lastChannelActions, [liveEvents.join]);
  });
}
