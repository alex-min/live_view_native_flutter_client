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

  group('Default currency settings', () {
    testWidgets(
      'currency changes preserve bottom navigation',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        SharedPreferences.setMockInitialValues({});

        final view = await LiveView.withPersistentCache();
        addTearDown(view.disconnect);
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _waitFor(
            tester, find.widgetWithText(ElevatedButton, 'Try the demo'));
        await tester.tap(find.widgetWithText(ElevatedButton, 'Try the demo'));

        // Complete the currency onboarding step (EUR is pre-selected).
        await _waitForUrl(
          tester,
          view,
          '/users/onboarding/currency',
          seconds: 30,
        );
        final nextButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await _waitFor(tester, nextButton, seconds: 30);
        await tester.tap(nextButton.last);

        // Demo balances in EUR require conversion after changing to ALL.
        await _waitForUrl(tester, view, '/accounts');
        await tester.pumpAndSettle();

        // Open settings through the same bottom navigation used by the app.
        await tester.tap(find.text('Settings').hitTestable().last);
        await _waitForUrl(tester, view, '/users/settings');
        await _waitFor(tester, find.text('Default currency'), seconds: 30);

        // A fresh demo defaults to EUR, shown as the row value badge
        // ("{code} · {symbol}", same label as the mobile web menu).
        final currentCurrency = find.textContaining('EUR ·');
        await _waitFor(tester, currentCurrency, seconds: 30);

        // Open the full-page currency picker by tapping the row.
        await tester.ensureVisible(currentCurrency.hitTestable().last);
        await tester.tap(currentCurrency.hitTestable().last);
        await tester.pump();
        await _waitForUrl(tester, view, '/currencies', seconds: 30);
        await _waitFor(tester, find.text('Currency picker'), seconds: 30);

        // Select ALL directly from the unfiltered list, matching the reported flow.
        final allRow = find.textContaining('ALL (');
        await _waitFor(tester, allRow.hitTestable(), seconds: 30);
        await tester.tap(allRow.last);
        await tester.pump();

        // Selecting a currency saves it server-side and navigates back to the
        // settings menu.
        await _waitForUrl(tester, view, '/users/settings', seconds: 30);
        await _waitFor(tester, find.textContaining('ALL ·'), seconds: 30);
        for (final tab in {
          'Accounts': '/accounts',
          'Home': '/dashboard',
          'Settings': '/users/settings'
        }.entries) {
          await tester.pumpAndSettle();
          await tester.tap(find.text(tab.key).hitTestable().last);
          await _waitForUrl(tester, view, tab.value);
        }
        expect(
          find.textContaining('ALL ·'),
          findsWidgets,
          reason: 'The saved currency should be shown as the row value badge',
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
