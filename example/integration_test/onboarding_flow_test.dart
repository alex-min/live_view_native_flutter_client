import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_button.dart';
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

  group('Onboarding flow', () {
    testWidgets(
      'sign up, accept the terms of service and open the settings page',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Tap the sign-up button on the home page to navigate to the
        // registration form via a real live-patch navigation.
        final signUpButton = find.byType(ElevatedButton).last;
        await _waitFor(tester, signUpButton, seconds: 30);
        await tester.tap(signUpButton);
        await _waitForUrl(tester, view, '/users/register', seconds: 30);

        // Wait for the cross-live_session fallback and the websocket join to
        // settle before interacting with the form.
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await _waitFor(tester, find.byType(TextField));

        final email =
            'integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
        const password = 'SuperSecret123!';

        final fields = find.byType(TextField);
        expect(
          fields,
          findsNWidgets(3),
          reason: 'The registration form should contain three text fields',
        );

        // Fill the form. Because the server sends validate diffs that can
        // reset field controllers, we fill the fields once, wait for the
        // response to settle, then refill the email right before submitting.
        await tester.enterText(fields.at(0), email);
        await tester.pump();
        await tester.enterText(fields.at(1), password);
        await tester.pump();
        await tester.enterText(fields.at(2), password);
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();

        await tester.enterText(fields.at(0), email);
        await tester.pump();

        final submitButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        expect(
          submitButton,
          findsOneWidget,
          reason: 'The registration form should have a submit button',
        );
        await tester.tap(submitButton);

        // Wait for the TOS page to appear after the registration redirect chain.
        await _waitForUrl(tester, view, '/users/accept-tos', seconds: 30);
        expect(
          view.currentUrl,
          '/users/accept-tos',
          reason: 'After sign-up the user should be redirected to the TOS page',
        );

        // The previous registration page is kept below the new page in the
        // router stack, so target the last (top-most) ElevatedButton.
        final acceptButton = find.byType(ElevatedButton).last;
        await tester.ensureVisible(acceptButton);
        await tester.tap(acceptButton);

        // Wait for the app bar to show the signed-in user's email.
        await _waitFor(tester, find.text(email), seconds: 30);
        await tester.pumpAndSettle();

        // The email is inside a TextButton wrapped with AbsorbPointer, so the
        // text itself is not hit-testable. Tap the button that contains it.
        final settingsButton =
            find.widgetWithText(LiveTextButton, email).last;
        expect(settingsButton, findsOneWidget,
            reason: 'The app bar should contain a settings button for the user');
        await tester.tap(settingsButton);
        await tester.pump();

        // Wait for the settings form to appear.
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);

        expect(
          find.text(email),
          findsWidgets,
          reason: 'The settings page should display the signed-in user',
        );
        expect(
          view.currentUrl,
          '/users/settings',
          reason: 'The user should be on the settings page',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Waits up to [seconds] for [finder] to match at least one widget,
/// pumping the tester each second.
Future<void> _waitFor(WidgetTester tester, Finder finder,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(WidgetTester tester, LiveView view, String url,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (view.currentUrl == url) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

/// Ensures the StartupKit dev server is running on [_serverHost]:[_serverPort].
///
/// If no server is listening, the dev database is migrated and seeded, then
/// `mix phx.server` is started. The server is left running so the test can
/// interact with a real Phoenix backend.
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

  final seed = await Process.run(
    'mix',
    ['run', 'priv/repo/seeds.exs'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  if (seed.exitCode != 0) {
    throw Exception('mix run seeds.exs failed:\n${seed.stderr}\n${seed.stdout}');
  }

  final process = await Process.start(
    'mix',
    ['phx.server'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  process.stdout.listen(stdout.add);
  process.stderr.listen(stderr.add);

  for (var i = 0; i < 60; i++) {
    if (await _serverReady()) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }

  throw Exception(
    'StartupKit server did not start on $_serverHost:$_serverPort',
  );
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
