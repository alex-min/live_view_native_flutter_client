import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Host and port where the StartupKit dev server is expected to run.
const _serverHost =
    String.fromEnvironment('SERVER_HOST', defaultValue: 'localhost');
const _serverPort = int.fromEnvironment('SERVER_PORT', defaultValue: 4000);

class _TestApp extends StatelessWidget {
  final LiveView view;

  const _TestApp({required this.view});

  @override
  Widget build(BuildContext context) => view.rootView;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);

  group('Currency picker', () {
    testWidgets(
      'lists currencies, filters by search and selects a currency',
      (tester) async {
        SharedPreferences.setMockInitialValues({});
        // Wide enough for the desktop app bar actions (window_width >= 900).
        await tester.binding.setSurfaceSize(const Size(1200, 900));

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/currencies');

        // Logged-out visitors get a single "Sign in" link in the app bar,
        // without any account email or "Sign up" button.
        await _waitFor(tester, find.widgetWithText(TextButton, 'Sign in'));
        expect(find.text('Sign up'), findsNothing);
        expect(find.textContaining('@'), findsNothing);

        // The picker lists currencies as native list tiles. The ListView
        // builds children lazily, so only the first currencies (AED, ...)
        // are in the widget tree before scrolling.
        await _waitFor(tester, find.byType(ListTile), seconds: 30);
        expect(
          find.textContaining('AED'),
          findsWidgets,
          reason: 'The currency list should start with AED',
        );

        // Searching filters the list server-side.
        final searchField = find.byType(TextField);
        await _waitFor(tester, searchField);
        await tester.enterText(searchField, 'euro');
        await tester.pump();
        await _waitFor(tester, find.text('EUR (€)'), seconds: 30);
        expect(
          find.textContaining('AED'),
          findsNothing,
          reason: 'AED should be filtered out after searching "euro"',
        );

        // Tapping a currency selects it.
        await tester.tap(find.text('EUR (€)'));
        await tester.pump();
        await _waitFor(tester, find.text('Euro'), seconds: 30);
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
