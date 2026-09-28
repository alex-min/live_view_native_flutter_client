import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Host and port where the StartupKit dev server is expected to run.
const _serverHost = 'localhost';
const _serverPort = 4000;

/// Mobile viewport wide enough for the settings app bar while still below
/// the 768px breakpoint so the mobile theme picker is used. The tall height
/// keeps every settings card on screen without scrolling.
const _mobileSize = Size(760, 2400);

class _TestApp extends StatelessWidget {
  final LiveView view;

  const _TestApp({required this.view});

  @override
  Widget build(BuildContext context) => view.rootView;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);

  group('Theme settings', () {
    testWidgets(
      'going back from the mobile theme picker without selecting keeps the current theme',
      (tester) async {
        final view = await _openMobileSettingsPage(tester);
        final initialTheme = view.themeSettings.themeName;

        // Tapping the back arrow closes the picker without changing the theme.
        final backButton = find.byIcon(Icons.arrow_back).hitTestable().last;
        await _waitFor(tester, backButton, seconds: 30);
        await tester.tap(backButton);
        await tester.pumpAndSettle();
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);

        expect(
          view.themeSettings.themeName,
          initialTheme,
          reason:
              'Going back without selecting a theme should keep the current theme',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
  group('Language settings', () {
    testWidgets('language background reaches the top without a white inset',
        (tester) async {
      final view = await _openMobileSettingsPage(tester,
          path: '/users/settings/language');
      tester.view.padding = const FakeViewPadding(top: 32);
      addTearDown(tester.view.resetPadding);
      await tester.pumpAndSettle();

      expect(find.byType(AppBar), findsNothing);
      final background = find.byType(LiveCosmicBackground).last;
      expect(tester.getTopLeft(background).dy, 0);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('Français'), findsOneWidget);

      await tester.tap(find.text('Français'));
      await _waitForUrl(tester, view, '/users/settings', seconds: 30);
      await _waitFor(tester, find.text('Langue'), seconds: 30);
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}

/// Signs up, completes onboarding, switches to a mobile viewport, opens the
/// settings page and opens the requested full-page settings picker.
Future<LiveView> _openMobileSettingsPage(WidgetTester tester,
    {String path = '/users/settings/theme'}) async {
  SharedPreferences.setMockInitialValues({});

  final view = LiveView();
  addTearDown(view.disconnect);
  view.catchExceptions = false;
  view.disableAnimations = true;
  view.throttleSpammyCalls = false;

  // Onboarding is unreliable at mobile sizes, so run it at a large viewport
  // first and switch afterwards.
  tester.view.physicalSize = const Size(1280, 800);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(_TestApp(view: view));
  await view.connect('http://$_serverHost:$_serverPort/');

  await _signUpAndOnboard(tester, view);
  await _waitForUrl(tester, view, '/home', seconds: 30);

  tester.view.physicalSize = _mobileSize;
  await tester.pumpAndSettle();

  // Navigate to settings and then to the full-page picker so the back arrow
  // has a previous route to return to.
  await view.livePatch('/users/settings');
  await _waitForUrl(tester, view, '/users/settings', seconds: 30);
  await view.livePatch(path);
  await _waitForUrl(tester, view, path, seconds: 30);
  await _waitFor(
      tester, find.text(path.endsWith('/theme') ? 'Ocean' : 'English'),
      seconds: 30);

  return view;
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// service). Mirrors the onboarding integration test.
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

  await _waitForUrl(tester, view, '/home', seconds: 30);
  await tester.pumpAndSettle();
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
