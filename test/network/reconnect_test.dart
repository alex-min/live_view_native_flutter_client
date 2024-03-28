import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fake_async/fake_async.dart';

import '../test_helpers.dart';

void main() {
  var view = LiveView();
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  var retries = 0;

  final MockClient failedNetwork = MockClient((request) async {
    retries += 1;
    throw const SocketException('Unable to connect');
  });

  view.httpClient = failedNetwork;
  view.liveSocket = FakeLiveSocket();

  test('reconnecting when having a network failure', () async {
    fakeAsync((async) {
      view.connect('http://localhost:9999');
      async.elapse(const Duration(seconds: 20));
    });
    expect(retries, 5);
  });
}
