import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

void main() {
  test('dead-view deletes open a fresh default HTTP client', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var clientsCreated = 0;
    var requests = <http.Request>[];
    var view = LiveView(
      httpClientFactory: () {
        clientsCreated++;
        return MockClient((request) async {
          requests.add(request);
          return http.Response('', 200);
        });
      },
    );
    view.host = 'localhost:9999';
    view.endpointScheme = 'http';

    await view.deadViewDeleteQuery('/users/log_out');

    expect(clientsCreated, 2);
    final delete = requests.singleWhere(
      (request) => request.method == 'DELETE',
    );
    expect(delete.headers['connection'], 'close');
  });
}
