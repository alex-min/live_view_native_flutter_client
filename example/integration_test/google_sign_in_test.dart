import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_google_sign_in_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _serverHost = 'localhost';
const _serverPort = 4000;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'Google sign-in is available on the native login page',
    (tester) async {
      await _ensureServer();
      SharedPreferences.setMockInitialValues({});

      var view = LiveView()
        ..catchExceptions = false
        ..disableAnimations = true
        ..throttleSpammyCalls = false;

      await tester.pumpWidget(_TestApp(view));
      await view.connect('http://$_serverHost:$_serverPort/users/log_in');

      for (var i = 0; i < 30; i++) {
        await tester.pump(const Duration(seconds: 1));
        if (find.byType(LiveGoogleSignInButton).evaluate().isNotEmpty) break;
      }

      expect(find.byType(LiveGoogleSignInButton), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp(this.view);
  final LiveView view;

  @override
  Widget build(BuildContext context) => view.rootView;
}

Future<void> _ensureServer() async {
  var socket = await Socket.connect(
    _serverHost,
    _serverPort,
    timeout: const Duration(seconds: 2),
  );
  await socket.close();
}
