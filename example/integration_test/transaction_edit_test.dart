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

  group('Transaction editing', () {
    testWidgets(
      'tapping a transaction opens the pre-filled edit form and saves',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = false;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');

        // The environment runs in a French locale, so assertions use the
        // French translations like the other integration tests.
        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/', seconds: 30);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Create an account.
        await view.livePatch('/accounts/new/manual');
        await _waitForUrl(tester, view, '/accounts/new/manual', seconds: 30);

        final accountFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, accountFields, seconds: 30);

        await tester.enterText(accountFields.at(0), '100');
        await tester.pump();
        await tester.enterText(accountFields.at(1), 'Edit account');
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(accountFields.at(0), '100');
        await tester.pump();
        await tester.enterText(accountFields.at(1), 'Edit account');
        await tester.pump();

        final saveButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.ensureVisible(saveButton);
        await tester.pumpAndSettle();
        await tester.tap(saveButton);
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Edit account'), seconds: 30);

        // Open the transaction list of the account.
        await tester.tap(find.text('Edit account').last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('No transactions yet'), seconds: 30);

        // Add a transaction through the app bar add button.
        await tester.tap(find.byIcon(Icons.add).last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/new(?:\?account_id=\d+)?$'),
          seconds: 30,
        );
        await _waitFor(tester, find.byIcon(Icons.close), seconds: 30);
        expect(find.byIcon(Icons.arrow_back), findsNothing);
        await _waitFor(tester, find.text('New transaction'), seconds: 30);

        // The date uses the native picker, leaving amount and description as
        // the form's two text fields.
        final transactionFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, transactionFields, seconds: 30);
        expect(
          transactionFields,
          findsNWidgets(2),
          reason: 'The transaction form should contain two text fields',
        );
        expect(
          tester.getTopLeft(transactionFields.first).dy,
          lessThan(tester.getTopLeft(find.text('Type')).dy),
          reason: 'The amount field should appear above the type selector',
        );

        await tester.enterText(transactionFields.at(0), '12.34');
        await tester.pump();
        await tester.enterText(transactionFields.at(1), 'Courses');
        await tester.pump();

        await tester.tap(find.byIcon(Icons.calendar_today_outlined));
        await tester.pumpAndSettle();
        await tester.tap(find.text('20').last);
        await tester.tap(find.text('OK'));
        await tester.pumpAndSettle();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(transactionFields.at(0), '12.34');
        await tester.pump();
        await tester.enterText(transactionFields.at(1), 'Courses');
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: find.byType(Form),
            matching: find.byType(ElevatedButton),
          ),
        );

        // Creating opens the selected account's transaction list and keeps
        // the newly created row near the middle of the viewport.
        await _waitForUrl(
          tester,
          view,
          RegExp(
            r'^/accounts/\d+/transactions\?focus_transaction_id=\d+$',
          ),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Courses'), seconds: 30);
        final createdRow = find.ancestor(
          of: find.text('Courses'),
          matching: find.byType(ListTile),
        );
        expect(
          (tester.getCenter(createdRow).dy -
                  tester.view.physicalSize.height / 2)
              .abs(),
          lessThan(90),
          reason: 'The created transaction should be centered in the list',
        );

        // Tap the transaction: the edit form opens, pre-filled.
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpAndSettle();
        await tester.tap(find.text('Courses').last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Edit transaction'), seconds: 30);

        // Mavio's edit screen replaces the normal navigation with one centered
        // close button and no bottom bar at all. Closing returns to the same
        // transaction-list route.
        expect(find.byType(BottomAppBar), findsNothing);
        expect(find.byType(BottomNavigationBar), findsNothing);
        final closeButton = find.byIcon(Icons.close).hitTestable();
        expect(closeButton, findsOneWidget);
        final closeFab = find.ancestor(
          of: closeButton,
          matching: find.byType(FloatingActionButton),
        );
        expect(
          tester.getBottomRight(closeFab).dy,
          lessThanOrEqualTo(tester.view.physicalSize.height - 16),
          reason: 'The close button should float clear of the screen bottom',
        );
        await tester.tap(closeButton);
        await tester.tap(closeButton, warnIfMissed: false);
        await _waitForUrl(
          tester,
          view,
          RegExp(
            r'^/accounts/\d+/transactions(?:\?focus_transaction_id=\d+)?$',
          ),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Courses'), seconds: 30);
        expect(find.text('Edit transaction'), findsNothing);
        expect(view.router.pages.last.page.name, view.currentUrl);
        expect(find.text('Courses').hitTestable(), findsOneWidget);

        await tester.tap(find.text('Courses').hitTestable().last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Edit transaction'), seconds: 30);

        // Returning must keep working after the list and edit routes have
        // already been rebuilt once.
        final secondCloseButton = find.byIcon(Icons.close).hitTestable();
        expect(secondCloseButton, findsOneWidget);
        await tester.tap(secondCloseButton);
        await _waitForUrl(
          tester,
          view,
          RegExp(
            r'^/accounts/\d+/transactions(?:\?focus_transaction_id=\d+)?$',
          ),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Courses'), seconds: 30);
        expect(find.text('Edit transaction'), findsNothing);
        expect(view.router.pages.last.page.name, view.currentUrl);
        expect(find.text('Courses').hitTestable(), findsOneWidget);

        await tester.tap(find.text('Courses').hitTestable().last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Edit transaction'), seconds: 30);

        final deleteButton = find.widgetWithText(OutlinedButton, 'Delete');
        await tester.ensureVisible(deleteButton);
        await tester.pumpAndSettle();
        await tester.tap(deleteButton);
        await _waitFor(tester, find.byType(AlertDialog), seconds: 30);
        expect(
          find.text('Are you sure you want to delete this transaction?'),
          findsOneWidget,
        );
        await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        final editFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await _waitFor(tester, editFields, seconds: 30);
        expect(editFields, findsNWidgets(2));

        // The description is pre-filled with the transaction's value.
        expect(
          find.widgetWithText(TextField, 'Courses'),
          findsOneWidget,
          reason: 'The description field should be pre-filled',
        );

        // Change the description and the amount, then save.
        await tester.enterText(editFields.at(0), '25.50');
        await tester.pump();
        await tester.enterText(editFields.at(1), 'Courses modifiées');
        await tester.pump();

        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();

        await tester.tap(
          find.descendant(
            of: find.byType(Form),
            matching: find.byType(ElevatedButton),
          ),
        );

        // Back on the transaction list with the updated row.
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Courses modifiées'), seconds: 30);
        expect(
          // English locale: "-€25.50" (expense, signed) formatted
          // server-side.
          find.textContaining('25.50'),
          findsWidgets,
          reason: 'The updated amount should appear in the row',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'creates an account transfer and updates both balances',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});

        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = true;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');
        await _signUpAndOnboard(tester, view);
        await _waitForUrl(tester, view, '/', seconds: 30);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await _createAccount(tester, view, name: 'Checking', balance: '200');
        await _createAccount(tester, view, name: 'Savings', balance: '50');

        // The transfer quick action is desktop-only on the mobile web
        // accounts page; create the transfer from the FAB and pick the
        // "Transfer" type in the form instead.
        await tester.tap(find.byIcon(Icons.add).last);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/new(?:\?account_id=\d+)?$'),
          seconds: 30,
        );
        await _waitFor(tester, find.byType(Form), seconds: 30);

        final transferOption = find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data == 'Transfer' || widget.data == 'Virement'),
        );
        await _waitFor(tester, transferOption, seconds: 30);
        await tester.ensureVisible(transferOption.last);
        await tester.tap(transferOption.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.byType(Form), seconds: 30);

        final dropdowns = find
            .descendant(
              of: find.byType(Form),
              matching: find.byType(DropdownButton<String>),
            )
            .hitTestable();
        expect(dropdowns, findsNWidgets(2));

        // The newest account (Savings) is selected as the source. Choose
        // Checking in the destination dropdown.
        await tester.tap(dropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Checking').last);
        await tester.pumpAndSettle();

        final fields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        expect(fields, findsNWidgets(3));
        await tester.enterText(fields.at(0), '25');
        await tester.pump();
        await tester.enterText(fields.at(2), 'Integration transfer');
        await tester.pump();

        final transferSaveButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.ensureVisible(transferSaveButton);
        await tester.pumpAndSettle();
        await tester.tap(transferSaveButton);

        await _waitForUrl(
          tester,
          view,
          RegExp(
            r'^/accounts/\d+/transactions\?focus_transaction_id=\d+$',
          ),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Integration transfer'), seconds: 30);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Savings'), seconds: 30);
        expect(find.textContaining('25'), findsWidgets);
        expect(find.textContaining('225'), findsWidgets);
        expect(find.textContaining('250'), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

Future<void> _createAccount(
  WidgetTester tester,
  LiveView view, {
  required String name,
  required String balance,
}) async {
  await view.livePatch('/accounts/new/manual');
  await _waitForUrl(tester, view, '/accounts/new/manual', seconds: 30);

  final fields = find.descendant(
    of: find.byType(Form),
    matching: find.byType(TextField),
  );
  await _waitFor(tester, fields, seconds: 30);
  await tester.enterText(fields.at(0), balance);
  await tester.pump();
  await tester.enterText(fields.at(1), name);
  await tester.pump();

  await Future.delayed(const Duration(seconds: 1));
  await tester.pump();
  await tester.enterText(fields.at(0), balance);
  await tester.pump();
  await tester.enterText(fields.at(1), name);
  await tester.pump();

  await tester.tap(
    find.descendant(
      of: find.byType(Form),
      matching: find.byType(ElevatedButton),
    ),
  );
  await _waitForUrl(tester, view, '/accounts', seconds: 30);
  await _waitFor(tester, find.text(name), seconds: 30);
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the accounts integration test.
Future<void> _signUpAndOnboard(WidgetTester tester, LiveView view) async {
  final signUpButton = find.widgetWithText(OutlinedButton, 'Sign up');
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
