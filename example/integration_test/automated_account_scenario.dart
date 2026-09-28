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

  group('Automated account', () {
    testWidgets(
      'automated account creation is gated behind Pro and shows a connect button for Pro users',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Open the account creation page.
        await view.livePatch('/accounts/new');
        await _waitForUrl(tester, view, '/accounts/new', seconds: 30);
        await _waitFor(tester, find.text('Automated'), seconds: 30);

        // Tapping Automated without Pro redirects to the Pro upsell page.
        await tester.tap(find.text('Automated').last);
        await tester.pumpAndSettle();
        await _waitForUrl(tester, view, '/pro', seconds: 30);
        await _waitFor(tester, find.text('Activate Pro (test)'), seconds: 30);

        // Upgrade to Pro.
        final activateButton = find.widgetWithText(
          TextButton,
          'Activate Pro (test)',
        );
        await _waitFor(tester, activateButton, seconds: 30);
        await tester.ensureVisible(activateButton);
        await tester.pumpAndSettle();
        // A flash snackbar covers the bottom of the page; dismiss it so the
        // tap reaches the button.
        await _dismissSnackbars(tester);
        await tester.tap(activateButton);
        await tester.pumpAndSettle();

        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await _waitFor(tester, find.text('Appearance'), seconds: 30);

        // With Pro active, the automated account page shows the provider
        // connect button.
        await view.livePatch('/accounts/new/automated');
        await _waitForUrl(tester, view, '/accounts/new/automated', seconds: 30);
        await _waitFor(tester, find.text('Connect with Plaid'), seconds: 30);
        await tester.pumpAndSettle();
        expect(find.byType(AppBar), findsNothing);
        expect(find.byIcon(Icons.arrow_back).hitTestable(), findsOneWidget);

        expect(
          find.widgetWithText(ElevatedButton, 'Connect with Plaid'),
          findsOneWidget,
        );
        expect(
          find.widgetWithText(ElevatedButton, 'Connect with Enable Banking'),
          findsOneWidget,
        );
        await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the other integration tests.
Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);

  await tester.pumpAndSettle();
  await Future.delayed(const Duration(milliseconds: 200));
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

  await tester.enterText(fields.at(0), email);
  await tester.pump();
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.enterText(fields.at(2), password);
  await tester.pump();

  await Future.delayed(const Duration(milliseconds: 200));
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

  await _waitForUrl(tester, view, '/users/onboarding/currency', seconds: 30);
  await _waitFor(tester, find.textContaining('EUR (€)'), seconds: 30);

  final nextButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await _waitFor(tester, nextButton, seconds: 30);
  await tester.tap(nextButton.last);

  await _waitForUrl(tester, view, '/accounts', seconds: 30);
  await tester.pumpAndSettle();

  // Signup and onboarding flashes show as snackbars on the accounts page;
  // dismiss them now so later taps are not swallowed.
  await _dismissSnackbars(tester);
}

/// Polls [finder] up to [seconds] times at 200 ms intervals.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Dismisses visible flash snackbars by tapping their close icon, which also
/// clears the flash server-side so it does not reappear on later renders.
/// Snackbars shift the FAB and cover bottom-aligned buttons.
Future<void> _dismissSnackbars(WidgetTester tester) async {
  for (var i = 0; i < 10; i++) {
    await tester.pump();
    final snackbar = find.byType(SnackBar);
    if (snackbar.evaluate().isEmpty) {
      return;
    }
    final close = find
        .descendant(of: snackbar, matching: find.byIcon(Icons.close))
        .hitTestable();
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close.first);
    }
    // Wait for the exit animation: while it runs, an AbsorbPointer in the
    // overlay still swallows taps.
    for (var j = 0; j < 15; j++) {
      await tester.pump();
      if (find.byType(SnackBar).evaluate().isEmpty) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
  }
}

/// Waits up to [seconds] for the live view to navigate to [url] (a plain
/// string or a [RegExp] matched against the current url).
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  Pattern url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final current = view.currentUrl;
    final matches = url is RegExp ? url.hasMatch(current) : current == url;
    if (matches && view.isCurrentRouteReady) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
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
    throw Exception(
      'mix run seeds.exs failed:\n${seed.stderr}\n${seed.stdout}',
    );
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
    await Future.delayed(const Duration(milliseconds: 200));
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
