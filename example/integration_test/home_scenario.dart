import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Host and port where the StartupKit dev server is expected to run.
const _serverHost = 'localhost';
const _serverPort = 4000;

class _TestApp extends StatelessWidget {
  final LiveView view;

  const _TestApp({required this.view});

  @override
  Widget build(BuildContext context) => view.rootView;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);

  group('Home page', () {
    testWidgets(
      'a signed-in user lands on the generic home page and can reach support',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // The bottom navigation only builds below the client's desktop
        // breakpoint, so run at a phone-sized viewport.
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _signUpAndAcceptTerms(tester, view);

        // The post-login landing page welcomes the user.
        await _waitForUrl(tester, view, '/home', seconds: 30);
        await _waitFor(tester, find.textContaining('Welcome to'), seconds: 30);
        await _waitFor(tester, find.text('Settings'), seconds: 30);

        // The bottom navigation mirrors Home/Support/Settings.
        final supportItem = find.text('Support').hitTestable();
        await _waitFor(tester, supportItem, seconds: 30);
        await tester.tap(supportItem);
        await _waitForUrl(tester, view, '/support', seconds: 30);

        // The support page lives in another live session without the bottom
        // bar, so navigate back to home explicitly.
        await view.livePatch('/home');
        await _waitForUrl(tester, view, '/home', seconds: 30);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// Registers a fresh user through the real form and accepts the terms of
/// service, landing on the generic home page.
Future<void> _signUpAndAcceptTerms(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);
  await tester.pumpAndSettle();

  await _waitFor(tester, find.byType(TextField));
  final email =
      'home-integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'SuperSecret123!';
  final fields = find.byType(TextField);
  expect(fields, findsNWidgets(3));
  await tester.enterText(fields.at(0), email);
  await tester.pump();
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.enterText(fields.at(2), password);
  await tester.pump();
  await tester.enterText(fields.at(0), email);
  await tester.pump();

  final submitButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await tester.tap(submitButton);
  await _waitForUrl(tester, view, '/users/accept-tos', seconds: 30);

  final acceptButton = find.byType(ElevatedButton).last;
  await tester.ensureVisible(acceptButton);
  await tester.tap(acceptButton);
}

/// Polls [finder] up to [seconds] times at one-second intervals.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var attempt = 0; attempt < seconds; attempt++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var attempt = 0; attempt < seconds * 10; attempt++) {
    await tester.pump();
    if (view.currentUrl == url && view.isCurrentRouteReady) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

Future<void> _ensureServer() async {
  if (await _serverReady()) {
    return;
  }

  final setup = await Process.run(
    'mix',
    ['ecto.setup'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  if (setup.exitCode != 0) {
    throw Exception('mix ecto.setup failed:\n${setup.stderr}\n${setup.stdout}');
  }

  final process = await Process.start(
    'mix',
    ['phx.server'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  process.stdout.listen(stdout.add);
  process.stderr.listen(stderr.add);

  for (var attempt = 0; attempt < 60; attempt++) {
    if (await _serverReady()) {
      return;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  throw Exception('StartupKit server did not start');
}

Future<bool> _serverReady() async {
  try {
    final socket = await Socket.connect(
      _serverHost,
      _serverPort,
      timeout: const Duration(seconds: 1),
    );
    socket.destroy();
    return true;
  } on Object {
    return false;
  }
}
