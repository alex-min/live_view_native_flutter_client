import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('diffs only update the current visit to the same URL', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      url: 'http://localhost:9999/form',
      rendered: {
        's': [
          '<viewBody><Form><Text>[[flutterState key=0]]</Text><DropdownButton name="account" initialValue="',
          '"><DropdownMenuItem value="1" label="Account" /></DropdownButton></Form></viewBody>',
        ],
        '0': '1',
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    view.currentUrl = '/other';
    view.handleRenderedMessage({
      's': ['<viewBody><Text>Other</Text></viewBody>'],
    });
    await tester.pumpAndSettle();
    view.currentUrl = '/form';
    view.handleRenderedMessage({
      's': ['<viewBody><Text>', '</Text></viewBody>'],
      '0': 'Current',
    });
    await tester.pumpAndSettle();
    expect(
      find.byType(DropdownButton<String>, skipOffstage: false),
      findsOneWidget,
    );
    view.handleDiffMessage({'0': 'Updated'});
    await tester.pumpAndSettle();
    expect(find.text('Updated'), findsOneWidget);
    // The first rebuild can wipe old state after navigation; a subsequent
    // diff must still leave that hidden visit untouched.
    view.handleDiffMessage({'0': 'Again'});
    await tester.pumpAndSettle();
    expect(find.text('Again'), findsOneWidget);
    final oldDropdown = tester.widget<DropdownButton<String>>(
      find.byType(DropdownButton<String>, skipOffstage: false),
    );
    expect(oldDropdown.value, '1');
    expect(find.text('1', skipOffstage: false), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('current page still receives diffs beneath a popup', (
    tester,
  ) async {
    final (view, _) = await connect(
      LiveView(),
      rendered: {
        's': ['<viewBody><Text>', '</Text></viewBody>'],
        '0': 'Before',
      },
    );
    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Before'));
    showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (_) => const AlertDialog(content: Text('Popup')),
    );
    await tester.pumpAndSettle();
    view.handleDiffMessage({'0': 'After'});
    await tester.pumpAndSettle();
    Navigator.of(context).pop();
    await tester.pumpAndSettle();
    expect(find.text('After'), findsOneWidget);
  });
  testWidgets(
    'checking page identity does not rebuild forms when a dropdown opens',
    (tester) async {
      final (view, _) = await connect(
        LiveView(),
        rendered: {
          's': [
            '<viewBody><Form><Text>',
            '</Text><DropdownButton name="account" initialValue="1"><DropdownMenuItem value="1" label="Checking" /><DropdownMenuItem value="2" label="Savings" /></DropdownButton></Form></viewBody>',
          ],
          '0': 'Before',
        },
      );
      await tester.runLiveView(view);
      await tester.pumpAndSettle();
      view.handleDiffMessage({'0': 'After'});
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      expect(find.text('Savings').hitTestable(), findsOneWidget);
      await tester.tap(find.text('Savings').hitTestable());
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        '2',
      );
    },
  );
}
