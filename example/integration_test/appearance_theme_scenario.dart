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

  group('Appearance settings', () {
    testWidgets(
      'sign up and switch between themes from the settings',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        // Use a tall viewport so the whole settings page fits without scrolling.
        tester.view.physicalSize = const Size(1280, 1600);
        tester.view.devicePixelRatio = 1.0;

        final email =
            'integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
        const password = 'SuperSecret123!';

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Navigate to the registration form.
        final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
        await _waitFor(tester, signUpButton, seconds: 30);
        await tester.tap(signUpButton);
        await _waitForUrl(tester, view, '/users/register', seconds: 30);

        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        await _waitFor(tester, find.byType(TextField));

        final fields = find.byType(TextField);
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

        // Accept the terms of service.
        await _waitForUrl(tester, view, '/users/accept-tos', seconds: 30);
        final acceptButton = find.byType(ElevatedButton).last;
        await tester.ensureVisible(acceptButton);
        await tester.tap(acceptButton);

        // Accepting the terms completes the onboarding and lands on the
        // generic home page.
        await _waitForUrl(tester, view, '/home', seconds: 30);

        // Wait for the generic home page after onboarding.
        await _waitFor(tester, find.textContaining('Welcome to'), seconds: 30);
        await tester.pumpAndSettle();
        await _dismissSnackbars(tester);

        // Navigate to the settings page, then into the appearance sub-page
        // where the theme tiles live.
        await view.livePatch('/users/settings');
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await _waitFor(tester, find.text('Appearance'), seconds: 30);
        await tester.tap(find.text('Appearance').hitTestable().last);
        await tester.pump();
        await _waitForUrl(tester, view, '/users/settings/theme', seconds: 30);
        await _waitFor(tester, find.text('Ocean'), seconds: 30);

        // Ocean is a premium theme; non-Pro users are redirected to /pro.
        final oceanTile = find.text('Ocean').hitTestable().last;
        await tester.ensureVisible(oceanTile);
        await tester.pumpAndSettle();
        await tester.tap(oceanTile);
        await tester.pumpAndSettle();

        await _waitForUrl(tester, view, '/pro', seconds: 30);

        // Upgrade to Pro using the test harness button.
        const activateProText = 'Activate Pro (test)';
        final activateButton = find.widgetWithText(TextButton, activateProText);
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

        // Now that the user is Pro, the Ocean theme can be selected.
        await tester.tap(find.text('Appearance').hitTestable().last);
        await tester.pump();
        await _waitForUrl(tester, view, '/users/settings/theme', seconds: 30);
        await _waitFor(tester, find.text('Ocean'), seconds: 30);
        final proOceanTile = find.text('Ocean').hitTestable().last;
        await tester.ensureVisible(proOceanTile);
        await tester.pumpAndSettle();
        await tester.tap(proOceanTile);
        await tester.pumpAndSettle();

        expect(
          view.themeSettings.themeName,
          'ocean',
          reason: 'The app should use the Ocean theme after tapping the tile',
        );
        expect(
          view.themeSettings.getDisplayedThemeMode(),
          ThemeMode.light,
          reason: 'Ocean is a light theme',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
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

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final currentPath = Uri.tryParse(view.currentUrl)?.path ?? '';
    if (currentPath == url && view.isCurrentRouteReady) {
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
