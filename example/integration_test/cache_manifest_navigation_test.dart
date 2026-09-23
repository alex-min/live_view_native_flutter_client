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

  testWidgets(
    'the authenticated manifest warms and presents all four primary routes',
    (tester) async {
      await _ensureServer();
      SharedPreferences.setMockInitialValues({});
      final view = await LiveView.withPersistentCache();
      view.catchExceptions = false;
      view.disableAnimations = true;
      view.throttleSpammyCalls = false;

      await tester.pumpWidget(_TestApp(view: view));
      await view.connect('http://$_serverHost:$_serverPort/');
      await _signUpAndOnboard(tester, view);

      await _waitForCachedRoutes(tester, view, const [
        '/dashboard',
        '/accounts',
        '/transactions',
        '/users/settings',
      ]);

      for (final route in const [
        '/dashboard',
        '/transactions',
        '/users/settings',
        '/accounts',
      ]) {
        await _expectCachedThenFresh(tester, view, route);
      }
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _waitForCachedRoutes(
  WidgetTester tester,
  LiveView view,
  List<String> routes,
) async {
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump();
    final coordinator = view.cacheCoordinator;
    if (coordinator != null && coordinator.namespace != null) {
      final snapshots = await Future.wait(
        routes.map(
          (route) => coordinator.loadForNavigation(Uri.parse(route)),
        ),
      );
      if (snapshots.every((snapshot) => snapshot != null)) {
        return;
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  final coordinator = view.cacheCoordinator;
  throw Exception(
    'Timed out waiting for all manifest routes to be cached '
    '(parsed=${view.cacheManifest?.routes.map((route) => route.href).toList()}, '
    'active=${coordinator?.manifest?.routes.map((route) => route.href).toList()}, '
    'namespace=${coordinator?.namespace})',
  );
}

Future<void> _expectCachedThenFresh(
  WidgetTester tester,
  LiveView view,
  String route,
) async {
  await view.livePatch(route);
  var sawCached = false;
  for (var attempt = 0; attempt < 300; attempt++) {
    await tester.pump();
    if (view.isShowingCachedRender) {
      sawCached = true;
      break;
    }
    if (view.currentUrl == route && view.isCurrentRouteReady) {
      break;
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  expect(sawCached, isTrue, reason: '$route should display its snapshot');

  await _waitForUrl(tester, view, route);
  expect(view.isShowingCachedRender, isFalse);
}

Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register');
  await tester.pumpAndSettle();
  await Future<void>.delayed(const Duration(seconds: 1));
  await tester.pumpAndSettle();

  await _waitFor(tester, find.byType(TextField));
  final email =
      'cache-integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'SuperSecret123!';
  final fields = find.byType(TextField);
  expect(fields, findsNWidgets(3));
  await tester.enterText(fields.at(0), email);
  await tester.pump();
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.enterText(fields.at(2), password);
  await tester.pump();
  await Future<void>.delayed(const Duration(seconds: 1));
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
  await tester.tap(nextButton.last);
  await _waitForUrl(tester, view, '/accounts');
}

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
