import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bar_chart.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
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

  group('Accounts', () {
    testWidgets(
      'shows the empty state, creates an account and marks it inactive',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});
        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // Sign up and complete the onboarding, like the onboarding flow test.
        await _signUpAndOnboard(tester, view);

        // The accounts page is the home page: once onboarding completes, the
        // app lands directly on it. The environment runs in a French locale,
        // so assertions use the French translations like the other
        // integration tests.
        await _waitForUrl(tester, view, '/', seconds: 30);

        // Empty state: no accounts yet, with a create button.
        await _waitFor(tester, find.text('Aucun compte pour le moment'),
            seconds: 30);
        expect(find.text('Relevé'), findsWidgets);
        expect(
          // The statement total is formatted server-side per the French
          // locale, without decimals for whole numbers: "0 €" with a
          // no-break space.
          find.text('0\u{00A0}€'),
          findsWidgets,
          reason: 'The statement total should be zero before any account',
        );

        // Open the creation form.
        await tester.tap(find.text('Créer un compte').last);
        await _waitForUrl(tester, view, '/accounts/new', seconds: 30);

        // The form has three text fields: initial balance, name, description.
        final fields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, fields, seconds: 30);
        expect(
          fields,
          findsNWidgets(3),
          reason: 'The account form should contain three text fields',
        );

        await tester.enterText(fields.at(0), '42.50');
        await tester.pump();
        await tester.enterText(fields.at(1), 'Integration account');
        await tester.pump();

        // The server sends validate diffs that can reset field controllers,
        // so refill right before submitting (same workaround as the
        // registration form in the onboarding flow test).
        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(fields.at(0), '42.50');
        await tester.pump();
        await tester.enterText(fields.at(1), 'Integration account');
        await tester.pump();

        // Submit the form. Currency defaults to the user's default currency
        // (EUR) and the type to cash.
        final submitButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        expect(submitButton, findsOneWidget);
        await tester.tap(submitButton);

        // Back on the list, the account appears with its balance and the
        // statement total is updated.
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);
        expect(
          // French locale: "42,50 €" with a no-break space.
          find.text('42,50\u{00A0}€'),
          findsAtLeastNWidgets(2),
          reason: 'The balance should appear in the row and in the statement',
        );

        // The Home item opens the Mavio-style dashboard. It shows the total
        // statement, the income/expense chart, and the recent-expense state.
        final floatingButtonState = tester.state(
          find.byType(LiveFloatingActionButton),
        );
        await view.livePatch('/dashboard');
        await _waitForUrl(tester, view, '/dashboard', seconds: 30);
        await _waitFor(tester, find.text('Accueil'), seconds: 30);
        expect(
          tester.state(find.byType(LiveFloatingActionButton)),
          same(floatingButtonState),
          reason: 'the docked action must persist while navigating',
        );
        expect(find.text('Relevé'), findsWidgets);
        expect(find.text('Revenus et dépenses'), findsOneWidget);
        expect(find.byType(LiveBarChart), findsOneWidget);
        expect(find.text('Dépenses récentes'), findsOneWidget);
        expect(find.text('Aucune dépense pour le moment'), findsOneWidget);
        expect(find.text('42,50\u{00A0}€'), findsWidgets);

        // Return to accounts after exercising the dashboard route.
        await view.livePatch('/');
        await _waitForUrl(tester, view, '/', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // Mark the account inactive through the row overflow menu.
        final overflowMenu = find.byIcon(Icons.more_vert);
        await _waitFor(tester, overflowMenu, seconds: 30);
        await tester.tap(overflowMenu.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Marquer comme inactif'), seconds: 30);
        await tester.tap(find.text('Marquer comme inactif').last);
        await tester.pump();

        // The account leaves the active list and an inactive section appears.
        await _waitFor(tester, find.text('Comptes inactifs (1)'), seconds: 30);
        expect(find.text('Integration account'), findsNothing);

        // Expanding the section shows the account again.
        await tester.tap(find.text('Comptes inactifs (1)').last);
        await tester.pump();
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // The row overflow menu offers to mark it active again.
        final inactiveOverflowMenu = find.byIcon(Icons.more_vert);
        await _waitFor(tester, inactiveOverflowMenu, seconds: 30);
        await tester.tap(inactiveOverflowMenu.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Marquer comme actif'), seconds: 30);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the onboarding flow integration test.
Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.byType(ElevatedButton).last;
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);

  // Wait for the cross-live_session fallback and the websocket join to
  // settle before interacting with the form.
  await tester.pumpAndSettle();
  await Future.delayed(const Duration(seconds: 1));
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

  await Future.delayed(const Duration(seconds: 1));
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

  // The signed-in user's email appears in the app bar once the onboarding
  // redirect chain lands on the home page.
  await _waitFor(tester, find.text(email), seconds: 30);
  await tester.pumpAndSettle();
}

/// Waits up to [seconds] for [finder] to match at least one widget,
/// pumping the tester each second.
Future<void> _waitFor(WidgetTester tester, Finder finder,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Waits up to [seconds] for the live view to navigate to [url].
Future<void> _waitForUrl(WidgetTester tester, LiveView view, String url,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (view.currentUrl == url) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
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

  for (var i = 0; i < 60; i++) {
    if (await _serverReady()) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
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
