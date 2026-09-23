import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

  testWidgets('dead-view posts open a fresh default HTTP client', (
    tester,
  ) async {
    var clientsCreated = 0;
    var requests = <http.Request>[];
    var view = LiveView(
      httpClientFactory: () {
        clientsCreated++;
        return MockClient((request) async {
          requests.add(request);
          return http.Response(xmlCsrf, 200);
        });
      },
    );
    view.liveSocket = FakeLiveSocket();
    await view.connect('http://localhost:9999');

    await view.deadViewPostQuery('/submit', {'value': 'one'});

    expect(clientsCreated, 2);
    expect(requests.where((request) => request.method == 'POST'), hasLength(1));
  });
}
