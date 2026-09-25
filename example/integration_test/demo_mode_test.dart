import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  group('Demo mode settings', () {
    testWidgets(
      'enters demo mode from settings and restores personal data on quit',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        // Wide enough to keep the whole settings menu on screen.
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        final view = await LiveView.withPersistentCache();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');
        final email = await _signUpAndOnboard(tester, view);

        await view.connect('http://$_serverHost:$_serverPort/users/settings');
        await _waitForUrl(tester, view, '/users/settings');
        await tester.pumpAndSettle();
        await Future.delayed(const Duration(milliseconds: 200));
        await tester.pumpAndSettle();

        // The More group lists the demo mode row; tapping it enters demo
        // mode like the mobile web settings menu. The row sits at the bottom
        // of the menu: scroll the top-most settings list until the text is
        // actually hit-testable (ListView builds children slightly offscreen,
        // so scrolling until the plain finder matches is not enough).
        final settingsList = find.byType(ListView).hitTestable().last;
        await tester.scrollUntilVisible(
          find.text('Try the app').hitTestable(),
          80,
          scrollable: find
              .descendant(
                of: settingsList,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        expect(find.text('Demo the app with fake data'), findsWidgets);

        final useDemoData = find.text('Try the app').hitTestable().last;
        await tester.tap(useDemoData);

        await _waitForUrl(tester, view, '/dashboard');
        await _waitFor(tester, find.text('Using demo data'));
        expect(find.text('Quit demo mode'), findsOneWidget);
        await _waitForCachedRoute(tester, view, '/accounts');

        // The demo app bar hides the account email while demo mode is on.
        // (The settings page stays mounted underneath with the email in its
        // form field, so only consider hit-testable text.)
        expect(find.text(email).hitTestable(), findsNothing);

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts');
        final quitDemoMode = find.widgetWithText(TextButton, 'Quit demo mode');
        await _waitFor(tester, quitDemoMode);
        await tester.ensureVisible(quitDemoMode.last);
        await tester.tap(quitDemoMode.last);

        await _waitForUrl(tester, view, '/accounts');
        await _waitForAbsent(tester, find.text('Using demo data'));

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts');
        await _waitFor(tester, find.text('No accounts yet'));
        await _waitForAbsent(tester, find.text('Cash'));
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

Future<void> _waitForCachedRoute(
  WidgetTester tester,
  LiveView view,
  String url,
) async {
  for (var i = 0; i < 300; i++) {
    await tester.pump();
    if (await view.cacheCoordinator?.loadForNavigation(Uri.parse(url)) !=
        null) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw Exception('Timed out waiting for cached route $url');
}

Future<String> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register');

  await tester.pumpAndSettle();
  await Future.delayed(const Duration(milliseconds: 200));
  await tester.pumpAndSettle();
  await _waitFor(tester, find.byType(TextField));

  final email =
      'integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'SuperSecret123!';
  final fields = find.byType(TextField);

  expect(fields, findsNWidgets(3));
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

  await _waitForUrl(tester, view, '/users/accept-tos');
  final acceptButton = find.byType(ElevatedButton).last;
  await tester.ensureVisible(acceptButton);
  await tester.tap(acceptButton);

  await _waitForUrl(tester, view, '/users/onboarding/currency');
  await _waitFor(tester, find.textContaining('EUR (€)'));

  final nextButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await _waitFor(tester, nextButton);
  await tester.tap(nextButton.last);

  await _waitFor(tester, find.text('No accounts yet'));
  await tester.pumpAndSettle();

  return email;
}

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

Future<void> _waitForAbsent(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for $finder to disappear');
}

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
    await Future.delayed(const Duration(milliseconds: 200));
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
