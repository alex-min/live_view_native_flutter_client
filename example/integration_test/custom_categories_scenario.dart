import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets(
    'a Pro user creates a custom category from settings',
    (tester) async {
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
      await Future.delayed(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();
      await _waitFor(tester, find.byType(TextField));

      var fields = find.byType(TextField);
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
      await _dismissSnackbars(tester);

      await view.livePatch('/pro');
      await _waitForUrl(tester, view, '/pro');
      final activate = find.widgetWithText(TextButton, 'Activate Pro (test)');
      await _waitFor(tester, activate);
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await _waitForUrl(tester, view, '/users/settings');

      tester.view.padding = const FakeViewPadding(top: 32);
      addTearDown(tester.view.resetPadding);
      final categorySettings = find.text('Custom categories');
      await tester.scrollUntilVisible(
        categorySettings,
        300,
        scrollable: find.byType(Scrollable).hitTestable().first,
      );
      await tester.pumpAndSettle();
      await tester.tap(categorySettings.last);
      await _waitForUrl(tester, view, '/settings/categories');
      await _waitFor(tester, find.text('Custom categories'));
      _expectBalancedPagePadding(tester);
      final add = find.widgetWithText(ElevatedButton, 'Add category');
      await _waitFor(tester, add);
      await tester.tap(add);
      await _waitForUrl(tester, view, '/settings/categories/new');

      await _waitFor(tester, find.byType(TextField));
      _expectBalancedPagePadding(tester);
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
    timeout: const Timeout(Duration(seconds: 20)),
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
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Dismisses visible flash snackbars by tapping their close icon, which also
/// clears the flash server-side so it does not reappear on later renders.
/// Snackbars cover bottom-aligned buttons such as "Activate Pro (test)".
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
    await Future.delayed(const Duration(milliseconds: 200));
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
    await Future.delayed(const Duration(milliseconds: 200));
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

void _expectBalancedPagePadding(WidgetTester tester) {
  expect(find.byType(AppBar), findsNothing);
  expect(tester.getTopLeft(find.byType(LiveCosmicBackground).last).dy, 0,
      reason: 'The page background must cover the top system inset');
  final list = find.byType(ListView).hitTestable().last;
  expect(
    tester.widget<ListView>(list).padding,
    const EdgeInsets.fromLTRB(16, 16, 16, 96),
    reason: 'Bottom-bar clearance must not become a large left margin',
  );
}
