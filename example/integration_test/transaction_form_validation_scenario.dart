import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Host and port where the StartupKit dev server is expected to run.
/// Overridable with `--dart-define=SERVER_HOST=...` / `SERVER_PORT=...`.
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

  group('Transaction form validation', () {
    testWidgets(
      'the hero amount input shows server validation errors on save',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Enter the demo account from the empty accounts page.
        await _signUpAndOnboard(tester, view);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        final tryDemo = find.widgetWithText(ElevatedButton, 'Try demo');
        await _waitFor(tester, tryDemo, seconds: 30);
        await tester.ensureVisible(tryDemo.last);
        await tester.tap(tryDemo.last.hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await view.livePatch('/transactions/new');
        await _waitForUrl(tester, view, '/transactions/new', seconds: 30);

        // The hero amount card: large bold font, currency symbol on the
        // left and the progress bar under the input.
        final amountFieldFinder = find.byWidgetPredicate((widget) {
          if (widget is! TextField) return false;
          final style = widget.style;
          return style?.fontSize == 32 &&
              style?.fontWeight == FontWeight.bold &&
              widget.decoration?.prefixText != null;
        });
        await _waitFor(tester, amountFieldFinder, seconds: 30);

        final amountField = tester.widget<TextField>(amountFieldFinder.first);
        expect(
          amountField.decoration?.prefixText?.trim().isNotEmpty,
          isTrue,
          reason: 'The hero amount should lead with the currency symbol',
        );
        expect(
          find.byWidgetPredicate(
            (widget) => widget is SizedBox && widget.height == 2,
          ),
          findsWidgets,
          reason: 'The bar under the amount input should render',
        );

        // Save with an empty amount: the server re-renders the form with
        // errors and the client displays them under the input.
        Future<void> saveEmpty() async {
          final saveButton = find.descendant(
            of: find.byType(Form),
            matching: find.byType(ElevatedButton),
          );
          await _waitFor(tester, saveButton, seconds: 30);
          await tester.ensureVisible(saveButton.first);
          await tester.tap(saveButton.first);
          await tester.pump();
        }

        await saveEmpty();
        await _waitFor(tester, find.textContaining('blank'), seconds: 30);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'the statistics screen renders the bottom bar without selection',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _signUpAndOnboard(tester, view);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        final tryDemo = find.widgetWithText(ElevatedButton, 'Try demo');
        await _waitFor(tester, tryDemo, seconds: 30);
        await tester.ensureVisible(tryDemo.last);
        await tester.tap(tryDemo.last.hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await view.livePatch('/statistics');
        await _waitForUrl(tester, view, '/statistics', seconds: 30);

        await _waitFor(tester, find.text('Statistics'), seconds: 30);

        // The bottom bar widget builds without throwing (catchExceptions is
        // false, so the old currentIndex assertion would fail the test here).
        // The "no selection" look itself is covered by the unit tests at a
        // true mobile width.
        await _waitFor(
          tester,
          find.byType(LiveBottomNavigationBar),
          seconds: 30,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

/// State-sensitive: runs alone in its own entrypoint (fresh
/// process), see transaction_locale_test.dart.
void localeMain() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);

  group('Transaction form locale', () {
    testWidgets(
      'the blank-amount validation error follows the session locale in French',
      (tester) async {
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _signUpAndOnboard(tester, view);

        // The transaction form needs an account: enter the demo account
        // from the empty accounts page.
        final tryDemo = find.widgetWithText(ElevatedButton, 'Try demo');
        await _waitFor(tester, tryDemo, seconds: 30);
        await tester.ensureVisible(tryDemo.last);
        await tester.tap(tryDemo.last.hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Switch the account language to French from the settings.
        await view.livePatch('/users/settings/language');
        await _waitForUrl(tester, view, '/users/settings/language',
            seconds: 30);
        final french = find.widgetWithText(ListTile, 'Français');
        await _waitFor(tester, french, seconds: 30);
        await tester.tap(french.first);
        await tester.pump();

        await view.livePatch('/transactions/new');
        await _waitForUrl(tester, view, '/transactions/new', seconds: 30);

        // Save with an empty amount: the server error follows the session
        // locale, not English.
        final saveButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await _waitFor(tester, saveButton, seconds: 30);
        await tester.ensureVisible(saveButton.first);
        await tester.tap(saveButton.first);
        await tester.pump();

        await _waitFor(
          tester,
          find.textContaining('ne peut pas être vide'),
          seconds: 30,
        );
        expect(find.textContaining('blank'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}

Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);

  // Wait for the cross-live_session fallback and the websocket join to
  // settle before interacting with the form.
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

  await _waitForUrl(tester, view, '/users/onboarding/currency', seconds: 30);
  await _waitFor(tester, find.textContaining('EUR (€)'), seconds: 30);

  final nextButton = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await _waitFor(tester, nextButton, seconds: 30);
  await tester.tap(nextButton.last);

  // The onboarding redirect chain lands on the accounts page.
  await _waitForUrl(tester, view, '/accounts', seconds: 30);
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
