import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('parses a server response with a top-level AppBar', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final view = LiveView();
    view.catchExceptions = false;
    await tester.pumpWidget(view.rootView);

    const body = '''
<csrf-token value="csrf"></csrf-token>
<AppBar>
  <title>
    <Text>StartupKit</Text>
  </title>
  <TextButton live-patch="/users/log_in"><Text>Sign in</Text></TextButton>
  <TextButton live-patch="/users/register"><Text>Sign up</Text></TextButton>
</AppBar>
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

    expect(
      widgets.whereType<LiveAppBar>(),
      isNotEmpty,
      reason: 'Expected a LiveAppBar in parsed widgets, got: $widgets',
    );

    view.router.updatePage(url: '/', widget: widgets, rootState: rootState);

    await tester.pumpAndSettle();

    expect(find.text('StartupKit'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Sign up'), findsOneWidget);
  });
}
