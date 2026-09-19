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
    'a Pro user creates a custom category from settings',
    (tester) async {
      await _ensureServer();
      SharedPreferences.setMockInitialValues({});

      final view = LiveView();
      view.catchExceptions = false;
      view.disableAnimations = true;
      view.throttleSpammyCalls = false;

      final email =
          'integration+categories-${DateTime.now().millisecondsSinceEpoch}@example.com';
      const password = 'SuperSecret123!';

      await tester.pumpWidget(_TestApp(view: view));
      await view.connect('http://$_serverHost:$_serverPort/');

      await _waitFor(tester, find.widgetWithText(OutlinedButton, 'Sign up'));
      await tester.tap(find.widgetWithText(OutlinedButton, 'Sign up'));
      await _waitForUrl(tester, view, '/users/register');
      await tester.pumpAndSettle();
      await Future.delayed(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      await _waitFor(tester, find.byType(TextField));

      var fields = find.byType(TextField);
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
      await tester.tap(
        find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ),
      );

      await _waitForUrl(tester, view, '/users/accept-tos');
      await tester.tap(find.byType(ElevatedButton).last);
      await _waitForUrl(tester, view, '/users/onboarding/currency');
      await _waitFor(tester, find.byType(ElevatedButton));
      await tester.tap(find.byType(ElevatedButton).last);
      await _waitFor(tester, find.text('No accounts yet'));

      await view.livePatch('/pro');
      await _waitForUrl(tester, view, '/pro');
      final activate = find.widgetWithText(TextButton, 'Activate Pro (test)');
      await _waitFor(tester, activate);
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await _waitForUrl(tester, view, '/users/settings');

      await view.livePatch('/settings/categories');
      await _waitForUrl(tester, view, '/settings/categories');
      await _waitFor(tester, find.text('Custom categories'));
      final add = find.widgetWithText(ElevatedButton, 'Add category');
      await _waitFor(tester, add);
      await tester.tap(add);
      await _waitForUrl(tester, view, '/settings/categories/new');

      await _waitFor(tester, find.byType(TextField));
      fields = find.byType(TextField);
      await tester.enterText(fields.first, 'Coffee runs');
      await tester.pump();

      final save = find.widgetWithText(ElevatedButton, 'Save category');
      await _waitFor(tester, save);
      await tester.ensureVisible(save);
      await tester.tap(save);

      await _waitForUrl(tester, view, '/settings/categories');
      await _waitFor(tester, find.text('Coffee runs'));
      expect(find.text('Coffee runs'), findsOneWidget);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) return;
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final currentPath = Uri.tryParse(view.currentUrl)?.path ?? '';
    if (currentPath == url && view.isCurrentRouteReady) return;
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

Future<void> _ensureServer() async {
  if (await _serverReady()) return;

  final setup = await Process.run(
    'mix',
    ['ecto.setup'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
  );
  if (setup.exitCode != 0) {
    throw Exception('mix ecto.setup failed:\n${setup.stderr}\n${setup.stdout}');
  }

  final process = await Process.start(
    'mix',
    ['phx.server'],
    workingDirectory: '../../startup_kit',
    environment: {'MIX_ENV': 'dev'},
    mode: ProcessStartMode.detachedWithStdio,
  );
  process.stdout.listen((_) {});
  process.stderr.listen((_) {});

  for (var i = 0; i < 60; i++) {
    if (await _serverReady()) return;
    await Future.delayed(const Duration(seconds: 1));
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
  } catch (_) {
    return false;
  }
}
