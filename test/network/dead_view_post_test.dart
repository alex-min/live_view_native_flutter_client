import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('dead-view posts do not reuse an idle HTTP connection', (
    tester,
  ) async {
    final view = LiveView();
    final (_, server) = await connect(view);

    await view.deadViewPostQuery('/submit', {'value': 'one'});

    final request = server.httpRequestsMade.last;
    expect(request.method, 'POST');
    expect(request.headers['connection'], 'close');
  });
}
