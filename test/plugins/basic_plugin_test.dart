import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';
import 'basic_plugin.dart';

void main() {
  testWidgets('basic plugin', (tester) async {
    var (view, _) =
        await connect(LiveView()..installPlugins([BasicPlugin()]), rendered: {
      's': [
        """
          <MyComponent phx-my-plugin="1"></MyComponent>
        """
      ],
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.allTexts(), ['MyComponent']);

    await tester.tap(find.text('MyComponent'), warnIfMissed: false);
    await tester.pumpAndSettle();

    expect(myPluginActions, ['1']);
  });
}
