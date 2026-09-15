import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('renders a persistent top bar above the routed body', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final view = LiveView();
    view.catchExceptions = false;
    await tester.pumpWidget(view.rootView);

    const body = '''
<csrf-token value="csrf"></csrf-token>
<PersistentTopBar>
  <Container><Text>Using demo data</Text></Container>
</PersistentTopBar>
<div id="phx-id" data-phx-session="session" data-phx-static="static" data-phx-main>
  <viewBody><Text>Dashboard</Text></viewBody>
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
    await tester.pumpAndSettle();

    expect(find.text('Using demo data'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);

    final topBar = tester.getTopLeft(find.text('Using demo data'));
    final bodyOffset = tester.getTopLeft(find.text('Dashboard'));
    expect(topBar.dy, lessThan(bodyOffset.dy));
  });
}
