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

  group('Default currency settings', () {
    testWidgets(
      'sign up and change the default currency from the settings',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        final email =
            'integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
        const password = 'SuperSecret123!';

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Navigate to the registration form.
        final signUpButton = find.byType(ElevatedButton).last;
        await _waitFor(tester, signUpButton, seconds: 30);
        await tester.tap(signUpButton);
        await _waitForUrl(tester, view, '/users/register', seconds: 30);

        await tester.pumpAndSettle();
        await Future.delayed(const Duration(seconds: 1));
        await tester.pumpAndSettle();

        await _waitFor(tester, find.byType(TextField));

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

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();

        await tester.enterText(fields.at(0), email);
        await tester.pump();

        final submitButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(submitButton);

        // Accept the terms of service.
        await _waitForUrl(tester, view, '/users/accept-tos', seconds: 30);
        final acceptButton = find.byType(ElevatedButton).last;
        await tester.ensureVisible(acceptButton);
        await tester.tap(acceptButton);

        // Wait for the app bar to show the signed-in user's email.
        await _waitFor(tester, find.text(email), seconds: 30);
        await tester.pumpAndSettle();

        // Navigate directly to the settings page.
        await view.connect('http://$_serverHost:$_serverPort/users/settings');
        await _waitFor(tester, find.text('Devise par défaut'), seconds: 30);

        // A fresh user defaults to EUR.
        expect(
          find.text('EUR (€)'),
          findsOneWidget,
          reason: 'A new user should default to EUR',
        );

        // Search for another currency and select it.
        final searchField = find.widgetWithText(TextField, 'Changer de devise');
        await _waitFor(tester, searchField, seconds: 30);
        await tester.ensureVisible(searchField);
        await tester.enterText(searchField, 'dollar');
        await tester.pump();
        await _waitFor(tester, find.text('USD (\$)'), seconds: 30);

        await tester.ensureVisible(find.text('USD (\$)'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('USD (\$)'));
        await tester.pump();

        // The selection replaces the current currency and collapses the list.
        await _waitFor(tester, find.text('USD (\$)'), seconds: 30);
        await _waitForDisappearance(tester, find.text('EUR (€)'), seconds: 30);
        expect(
          find.text('US Dollar'),
          findsOneWidget,
          reason: 'The selected currency should be shown in the card',
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

/// Waits up to [seconds] for [finder] to stop matching any widget.
Future<void> _waitForDisappearance(WidgetTester tester, Finder finder,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder to disappear');
}

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(WidgetTester tester, LiveView view, String url,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final currentPath = Uri.tryParse(view.currentUrl ?? '')?.path ?? '';
    if (currentPath == url) {
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
        'mix run seeds.exs failed:\n${seed.stderr}\n${seed.stdout}');
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
