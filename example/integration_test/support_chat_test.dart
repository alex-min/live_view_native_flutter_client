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

  group('Support chat', () {
    testWidgets(
      'an anonymous visitor taps the bubble, sends a message and sees it',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Anonymous users land on the landing page which renders the
        // floating support bubble.
        await _waitFor(tester, find.byIcon(Icons.chat_bubble), seconds: 30);
        await tester.tap(find.byIcon(Icons.chat_bubble));
        await _waitForUrl(tester, view, '/support', seconds: 30);

        expect(find.byType(AppBar), findsNothing);
        expect(find.byIcon(Icons.arrow_back), findsOneWidget);
        expect(
          view.router.pages.where((page) => page.page.name == '/').length,
          1,
          reason: 'Opening support must preserve the previous route',
        );

        // The composer renders with the multiline body field.
        await _waitFor(tester, find.byType(TextField), seconds: 30);
        const message = 'Hello, I need help with my account';
        await tester.enterText(find.byType(TextField).first, message);
        await tester.pump();

        final sendButton = find.byIcon(Icons.send);
        await _waitFor(tester, sendButton, seconds: 30);
        await tester.tap(sendButton.first);
        await tester.pump();

        // The message appears in the thread and the composer is cleared
        // by the server-pushed clear-composer event.
        await _waitFor(tester, find.text(message), seconds: 30);
        final field = tester.widget<TextField>(find.byType(TextField).first);
        expect(field.controller?.text ?? '', isEmpty);

        await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
        await _waitForUrl(tester, view, '/', seconds: 30);
        expect(find.text('Welcome to Mavio'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'an authenticated visitor returns from chat with its back button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');
        await _waitFor(tester, find.text('Welcome to Mavio'), seconds: 30);
        await tester.tap(
          find.widgetWithText(ElevatedButton, 'Try the demo').hitTestable(),
        );
        await _waitForUrl(
          tester,
          view,
          '/users/onboarding/currency',
          seconds: 30,
        );
        final nextButton = find.descendant(
          of: find.byType(Form),
          matching: find.widgetWithText(ElevatedButton, 'Next'),
        );
        await _waitFor(tester, nextButton, seconds: 30);
        await tester.tap(nextButton.last);
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await _waitFor(tester, find.byIcon(Icons.chat_bubble), seconds: 30);
        await tester.tap(find.byIcon(Icons.chat_bubble).hitTestable());
        await _waitForUrl(tester, view, '/support', seconds: 30);

        await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// Waits up to [seconds] for [finder] to match at least one widget,
/// pumping the tester each second.
Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 10,
  String? reason,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump(const Duration(seconds: 1));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'Timed out waiting for ${finder.toString()}${reason != null ? ': $reason' : ''}',
  );
}

Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String path, {
  int seconds = 10,
}) async {
  for (var i = 0; i < seconds * 2; i++) {
    await tester.pump(const Duration(milliseconds: 500));
    if (view.router.pages.isNotEmpty &&
        view.router.pages.last.page.name == path &&
        view.isCurrentRouteReady) {
      return;
    }
  }
  fail('Timed out waiting for url $path (got ${view.currentUrl})');
}

Future<void> _ensureServer() async {
  for (var i = 0; i < 60; i++) {
    try {
      final socket = await Socket.connect(
        _serverHost,
        _serverPort,
        timeout: const Duration(seconds: 1),
      );
      await socket.close();
      return;
    } catch (_) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
  }
  fail(
    'The StartupKit server is not reachable at '
    '$_serverHost:$_serverPort. Start it with `mix phx.server` '
    'before running the integration tests.',
  );
}
