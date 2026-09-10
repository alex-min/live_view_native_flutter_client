import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
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

  group('Account picker', () {
    testWidgets(
      'closing the account picker with the back arrow keeps the current account',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        // Onboarding is unreliable at mobile sizes because of app-bar overflow,
        // so run it at a large viewport and switch to mobile afterwards.
        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/', seconds: 30);

        // The account picker is only a full-page view on small screens.
        // Use 700px width to stay under the mobile breakpoint while giving
        // the app bar enough room for its title and actions.
        tester.view.physicalSize = const Size(700, 800);
        await tester.pumpAndSettle();

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Create two accounts so there is a choice in the picker.
        await _createAccount(tester, view, 'Account A', '100');
        await _createAccount(tester, view, 'Account B', '100');

        // Open the new-transaction form.
        await view.livePatch('/transactions/new');
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/new(?:\?account_id=\d+)?$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('New transaction'), seconds: 30);

        // The mobile account field is a tappable ListTile.
        final initialAccount =
            find.textContaining(RegExp(r'^Account [AB]$')).hitTestable();
        await _waitFor(tester, initialAccount, seconds: 30);
        await tester.tap(initialAccount.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Select account'), seconds: 30);

        // Tapping the back arrow closes the picker without changing the account.
        final closePicker =
            find.widgetWithIcon(IconButton, Icons.arrow_back).hitTestable();
        await _waitFor(tester, closePicker, seconds: 30);
        expect(
          view.sendEvent(
            ExecLiveEvent(
              type: 'click',
              name: 'close_account_picker',
              value: const {},
            ),
          ),
          isTrue,
        );
        await _waitFor(tester, find.text('New transaction'), seconds: 30);
        expect(find.text('Select account'), findsNothing);
        expect(find.textContaining('<Form'), findsNothing);
        expect(find.text('Account B'), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'selecting an account in the picker saves the transaction to that account',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        tester.view.physicalSize = const Size(1280, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/', seconds: 30);

        tester.view.physicalSize = const Size(700, 800);
        await tester.pumpAndSettle();

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await _createAccount(tester, view, 'Account A', '100');
        await _createAccount(tester, view, 'Account B', '100');

        await view.livePatch('/transactions/new');
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/new(?:\?account_id=\d+)?$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('New transaction'), seconds: 30);

        // Open the account picker by tapping whichever account is currently
        // selected in the form.
        final initialAccount =
            find.textContaining(RegExp(r'^Account [AB]$')).hitTestable();
        await _waitFor(tester, initialAccount, seconds: 30);
        await tester.tap(initialAccount.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Select account'), seconds: 30);

        await tester.tap(find.text('Account A').hitTestable().last);
        await tester.pumpAndSettle();

        await _waitFor(tester, find.text('New transaction'), seconds: 30);
        expect(find.text('Account A'), findsWidgets);

        final amountField = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, amountField, seconds: 30);
        await tester.enterText(amountField.at(0), '12.34');
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(amountField.at(0), '12.34');
        await tester.pump();

        final transactionSave = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.ensureVisible(transactionSave);
        await tester.tap(transactionSave);

        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Open Account A's transaction list to verify the transaction landed there.
        await _waitFor(
          tester,
          find.text('Account A').hitTestable(),
          seconds: 30,
        );
        await tester.tap(find.text('Account A').hitTestable().last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(tester, find.textContaining('12.34'), seconds: 30);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

Future<void> _createAccount(
  WidgetTester tester,
  LiveView view,
  String name,
  String balance,
) async {
  // Navigate directly to the manual creation form to avoid relying on
  // translated labels and ambiguous add buttons.
  await view.livePatch('/accounts/new/manual');
  await _waitForUrl(tester, view, '/accounts/new/manual', seconds: 30);

  final accountFields = find.descendant(
    of: find.byType(Form),
    matching: find.byType(TextField),
  );
  await _waitFor(tester, accountFields, seconds: 30);

  await tester.enterText(accountFields.at(0), balance);
  await tester.pump();
  await tester.enterText(accountFields.at(1), name);
  await tester.pump();

  await Future.delayed(const Duration(seconds: 1));
  await tester.pump();
  await tester.enterText(accountFields.at(0), balance);
  await tester.pump();
  await tester.enterText(accountFields.at(1), name);
  await tester.pump();

  final accountSave = find.descendant(
    of: find.byType(Form),
    matching: find.byType(ElevatedButton),
  );
  await tester.ensureVisible(accountSave);
  await tester.tap(accountSave);
  await _waitForUrl(tester, view, '/accounts', seconds: 30);
  await _waitFor(tester, find.text(name), seconds: 30);
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the accounts integration test.
Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.byType(ElevatedButton).last;
  await _waitFor(tester, signUpButton, seconds: 30);
  await tester.tap(signUpButton);
  await _waitForUrl(tester, view, '/users/register', seconds: 30);

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

  await _waitFor(tester, find.text(email), seconds: 30);
  await tester.pumpAndSettle();
}

/// Waits up to [seconds] for [finder] to match at least one widget,
/// pumping the tester each second.
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
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder');
}

/// Waits up to [seconds] for the live view to navigate to [url] (a plain
/// string or a [RegExp] matched against the current url).
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  Pattern url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    final current = view.currentUrl;
    final matches = url is RegExp ? url.hasMatch(current) : current == url;
    if (matches && view.isCurrentRouteReady) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

/// Ensures the StartupKit dev server is running on [_serverHost]:[_serverPort].
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
