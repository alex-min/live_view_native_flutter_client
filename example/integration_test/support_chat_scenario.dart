import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/live_view/cache/live_cache_manifest.dart';
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
        expect(find.textContaining('Welcome to'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'an authenticated visitor returns from chat with its back button',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = await LiveView.withPersistentCache();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');
        await _waitFor(tester, find.textContaining('Welcome to'), seconds: 30);
        await _signUpAndOnboard(tester, view);
        await _waitForUserCache(tester, view);

        await _waitFor(tester, find.byIcon(Icons.chat_bubble), seconds: 30);
        await tester.tap(find.byIcon(Icons.chat_bubble).hitTestable());
        await _waitForUrl(tester, view, '/support', seconds: 30);
        expect(
          view.router.pages.any((page) => page.page.name == '/home'),
          isTrue,
          reason: 'The full-page chat must keep its previous route',
        );

        await tester.tap(find.byIcon(Icons.arrow_back).hitTestable());
        await _waitForUrl(tester, view, '/home', seconds: 30);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// Registers a fresh user through the real form and accepts the terms of
/// service, landing on the generic home page.
Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);
  await tester.pumpAndSettle();

  await _waitFor(tester, find.byType(TextField));
  final email =
      'chat-integration+${DateTime.now().millisecondsSinceEpoch}@example.com';
  const password = 'SuperSecret123!';
  final fields = find.byType(TextField);
  await tester.enterText(fields.at(0), email);
  await tester.pump();
  await tester.enterText(fields.at(1), password);
  await tester.pump();
  await tester.enterText(fields.at(2), password);
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

Future<void> _waitForUserCache(WidgetTester tester, LiveView view) async {
  for (var attempt = 0; attempt < 50; attempt++) {
    await tester.pump();
    if (view.cacheCoordinator?.namespace?.scope == LiveCacheScope.user) return;
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  fail('Timed out waiting for the authenticated cache policy');
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
