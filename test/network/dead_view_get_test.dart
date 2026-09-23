import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_helpers.dart';

void main() {
  testWidgets('dead-view gets retry a stale default HTTP connection once', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    var clientsCreated = 0;
    var getAttempts = 0;
    var getClientIds = <int>[];
    var view = LiveView(
      httpClientFactory: () {
        clientsCreated++;
        var clientId = clientsCreated;
        return MockClient((request) async {
          if (request.method == 'GET') {
            getAttempts++;
            getClientIds.add(clientId);
            if (getAttempts == 1) {
              throw http.ClientException(
                'Connection closed before full header was received',
                request.url,
              );
            }
          }
          return http.Response(xmlCsrf, 200);
        });
      },
    );
    view.liveSocket = FakeLiveSocket();

    await view.connect('http://localhost:9999');

    expect(clientsCreated, greaterThanOrEqualTo(2));
    expect(getAttempts, greaterThanOrEqualTo(2));
    expect(getClientIds.take(2), [1, 2]);
    expect(view.currentUrl, '/');
  });
}
