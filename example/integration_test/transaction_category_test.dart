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

  group('Transaction categories', () {
    testWidgets(
      'picking a category shows its name in the list and pre-selects it on edit',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // The environment runs in a French locale, so assertions use the
        // French translations like the other integration tests.
        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/', seconds: 30);

        // Create an account.
        await _waitFor(tester, find.text('Créer un compte'), seconds: 30);
        await tester.tap(find.text('Créer un compte').last);
        await _waitForUrl(tester, view, '/accounts/new', seconds: 30);

        final accountFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, accountFields, seconds: 30);

        await tester.enterText(accountFields.at(0), '100');
        await tester.pump();
        await tester.enterText(accountFields.at(1), 'Category account');
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(accountFields.at(0), '100');
        await tester.pump();
        await tester.enterText(accountFields.at(1), 'Category account');
        await tester.pump();

        await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ));
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Category account'), seconds: 30);

        // Open the new-transaction form from the transaction list.
        await tester.tap(find.text('Category account').last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(
          tester,
          find.text('Aucune transaction pour le moment'),
          seconds: 30,
        );
        await tester.tap(find.byIcon(Icons.add).last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/new\?account_id=\d+$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Nouvelle transaction'), seconds: 30);

        // The category dropdown is the second of the form (type, category,
        // account).
        final dropdowns = find.descendant(
          of: find.byType(Form),
          matching: find.byType(DropdownButton<String>),
        );
        await _waitFor(tester, dropdowns, seconds: 30);
        expect(
          dropdowns,
          findsNWidgets(3),
          reason: 'The transaction form should have three dropdowns',
        );

        // Pick the "Bonus" category (near the top of the income groups, so
        // it is visible without scrolling the popup). Bonus is an income
        // kind: the category overrides the type selected in the form (mavio
        // behavior).
        await tester.ensureVisible(dropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(dropdowns.at(1));
        await tester.pumpAndSettle();
        expect(find.text('Bonus'), findsWidgets);
        await tester.tap(find.text('Bonus').last);
        await tester.pumpAndSettle();

        // Fill the amount and submit (no description: the category name
        // becomes the row label).
        final amountField = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(amountField.at(0), '12.34');
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(amountField.at(0), '12.34');
        await tester.pump();

        await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ));

        // Back on the accounts page; reopen the transaction list.
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Category account'), seconds: 30);
        await tester.tap(find.text('Category account').last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );

        // The row is labeled with the localized category name.
        await _waitFor(tester, find.text('Bonus'), seconds: 30);

        // Open the edit form: the category dropdown is pre-selected.
        await tester.tap(find.text('Bonus').last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Modifier la transaction'),
            seconds: 30);

        final editDropdowns = find.descendant(
          of: find.byType(Form),
          matching: find.byType(DropdownButton<String>),
        );
        await _waitFor(tester, editDropdowns, seconds: 30);
        expect(
          find.descendant(
            of: editDropdowns.at(1),
            matching: find.text('Bonus'),
          ),
          findsOneWidget,
          reason: 'The category dropdown should be pre-selected on edit',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the accounts integration test.
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

/// Waits up to [seconds] for the live view to navigate to [url] (a plain
/// string or a [RegExp] matched against the current url).
Future<void> _waitForUrl(WidgetTester tester, LiveView view, Pattern url,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final current = view.currentUrl;
    final matches = url is RegExp ? url.hasMatch(current) : current == url;
    if (matches) {
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
