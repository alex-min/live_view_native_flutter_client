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

  group('Demo account onboarding', () {
    testWidgets(
      'try the demo, pick a currency and claim the account by email',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Cookieless visitors are bounced to the /welcome start screen.
        await _waitForUrl(tester, view, '/', seconds: 30);
        await _waitFor(tester, find.text('Welcome to Mavio'), seconds: 30);
        final tryTheDemo = find.widgetWithText(ElevatedButton, 'Try the demo');
        await _waitFor(tester, tryTheDemo, seconds: 30);

        // The button submits the POST /users/demo form, which creates a
        // demo user, logs them in and bounces them into the onboarding.
        // Demo users skip the terms of service step, so the currency step
        // is their whole onboarding.
        await tester.tap(tryTheDemo);

        // The onboarding step asks for the default currency, with EUR
        // pre-selected.
        await _waitForUrl(
          tester,
          view,
          '/users/onboarding/currency',
          seconds: 30,
        );
        await _waitFor(tester, find.textContaining('EUR (€)'), seconds: 30);

        final nextButton = find.descendant(
          of: find.byType(Form),
          matching: find.widgetWithText(ElevatedButton, 'Next'),
        );
        await _waitFor(tester, nextButton, seconds: 30);
        await tester.tap(nextButton.last);

        // Demo users land on the accounts page with the demo dataset
        // already seeded by the currency onboarding step. The list is
        // virtualized, so assert on the first row ("Stock picks" sorts
        // above "Cash") and on the empty state being gone.
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Stock picks'), seconds: 30);
        expect(
          find.text('No accounts yet'),
          findsNothing,
          reason: 'Demo accounts should get the demo dataset on onboarding',
        );

        // The demo email is hidden from the app bar; the settings page is
        // still reachable through the bottom navigation.
        expect(
          find.textContaining('@demo.com'),
          findsNothing,
          reason: 'The demo account email should not appear in the app bar',
        );
        await view.livePatch('/users/settings');
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await tester.pumpAndSettle();

        // Demo users see the claim banner and their email is not sudo-locked.
        await _waitFor(
          tester,
          find.text('This demo account and all its data will be deleted soon.'),
          seconds: 30,
        );
        expect(
          find.text('Sensitive changes are locked'),
          findsNothing,
          reason: 'Demo accounts should not need sudo mode to change email',
        );

        // Change the email to a unique address, without any password prompt.
        final newEmail =
            'demo+${DateTime.now().millisecondsSinceEpoch}@example.com';
        final claimButton = find.widgetWithText(TextButton, 'Claim');
        await _waitFor(tester, claimButton, seconds: 30);
        await tester.ensureVisible(claimButton.last);
        await tester.pump();
        await tester.tap(claimButton.last);
        await _waitForUrl(tester, view, '/users/claim', seconds: 30);
        await tester.pumpAndSettle();

        final emailField = find.widgetWithText(TextField, 'Email');
        await _waitFor(tester, emailField, seconds: 30);
        await tester.enterText(emailField, newEmail);
        await tester.pump();

        // phx-change can replace the field controller. Refill after that
        // diff settles, then submit.
        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(emailField, newEmail);
        await tester.pump();

        final claimAccountButton = find.widgetWithText(
          ElevatedButton,
          'Claim account',
        );
        await _waitFor(tester, claimAccountButton, seconds: 30);
        await tester.ensureVisible(claimAccountButton);
        await tester.pump();
        await tester.tap(claimAccountButton);
        await tester.pump();

        // The confirmation link email is covered by the web tests; here we
        // only assert the "link sent" feedback flash.
        await _waitFor(
          tester,
          find.text(
            'A link to confirm your email change has been sent to the new address.',
          ),
          seconds: 30,
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Waits up to [seconds] for [finder] to match at least one widget,
/// pumping the tester each second.
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
    await Future.delayed(const Duration(seconds: 1));
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
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (view.currentUrl == url && view.isCurrentRouteReady) {
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
