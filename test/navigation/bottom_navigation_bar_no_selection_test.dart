import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('a negative initialValue renders without selection', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody><Text>Statistics page</Text></viewBody>
          <BottomNavigationBar initialValue="-1" selectedItemColor="blue-500" unselectedItemColor="grey-500">
            <BottomNavigationBarItem live-patch="/dashboard" live-patch-mode="replace" icon="home" label="Home" />
            <BottomNavigationBarItem live-patch="/accounts" live-patch-mode="replace" icon="account_balance" label="Accounts" />
            <BottomNavigationBarItem live-patch="/transactions" live-patch-mode="replace" icon="swap_vert" label="Transactions" />
            <BottomNavigationBarItem live-patch="/users/settings" live-patch-mode="replace" icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    // The out of range index is clamped so Material does not assert, and no
    // item gets the selected look.
    expect(bar.currentIndex, 0);
    expect(bar.selectedItemColor, bar.unselectedItemColor);
    expect(bar.selectedFontSize, bar.unselectedFontSize);
    expect(find.text('Statistics page'), findsOneWidget);
  });

  testWidgets('an in-range initialValue keeps the selected look', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 800));

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
        <flutter>
          <viewBody><Text>Accounts page</Text></viewBody>
          <BottomNavigationBar initialValue="1" selectedItemColor="blue-500" unselectedItemColor="grey-500">
            <BottomNavigationBarItem live-patch="/dashboard" live-patch-mode="replace" icon="home" label="Home" />
            <BottomNavigationBarItem live-patch="/accounts" live-patch-mode="replace" icon="account_balance" label="Accounts" />
            <BottomNavigationBarItem live-patch="/transactions" live-patch-mode="replace" icon="swap_vert" label="Transactions" />
            <BottomNavigationBarItem live-patch="/users/settings" live-patch-mode="replace" icon="settings" label="Settings" />
          </BottomNavigationBar>
        </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    var bar = tester.widget<BottomNavigationBar>(
      find.byType(BottomNavigationBar),
    );
    expect(bar.currentIndex, 1);
    expect(bar.selectedItemColor, isNot(bar.unselectedItemColor));
  });
}
