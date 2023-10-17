import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('hides and shows back an id', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '<ListView><Text id="hello">hello</Text><ElevatedButton ',
        '></ElevatedButton></ListView>',
      ],
      '0': 'phx-click="${FlutterExec.encode([
            FlutterExecAction(name: 'hide', value: {'to': '#hello'})
          ])}"',
    });
    await tester.runLiveView(view);

    await tester.pumpAndSettle();
    expect(find.firstText(), 'hello');
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(find.firstText(), null);

    await tester.tap(find.byType(LiveElevatedButton));
    view.handleDiffMessage({
      '0': 'phx-click="${FlutterExec.encode([
            FlutterExecAction(name: 'show', value: {'to': '#hello'})
          ])}"'
    });

    await tester.pumpAndSettle();

    await tester.pumpAndSettle();
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();
    expect(find.firstText(), 'hello');
  });

  testWidgets('hides itself', (tester) async {
    var (view, server) = await connect(LiveView(), rendered: {
      's': [
        '<ElevatedButton ',
        '>click me</ElevatedButton>',
      ],
      '0': 'phx-click="${FlutterExec.encode([
            FlutterExecAction(name: 'hide')
          ])}"',
    });

    await tester.runLiveView(view);

    await tester.pumpAndSettle();
    expect(find.firstText(), 'click me');
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();
    expect(find.firstText(), null);
  });
}
