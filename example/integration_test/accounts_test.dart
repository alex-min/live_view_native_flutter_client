import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bar_chart.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_month_picker_drawer.dart';
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

        // Onboarding lands on the dashboard. Open its statement card to reach
        // the accounts screen before asserting the empty state.
        await _waitForUrl(tester, view, '/', seconds: 30);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Empty state: no accounts yet, with a create button.
        await _waitFor(tester, find.text('No accounts yet'), seconds: 30);
        expect(find.text('Statement'), findsWidgets);
        expect(
          // The statement total is formatted server-side in the persisted
          // English locale.
          find.text('€0'),
          findsWidgets,
          reason: 'The statement total should be zero before any account',
        );

        // Open the creation form.
        final createAccount = find.text('Create an account').last;
        await tester.ensureVisible(createAccount);
        await tester.tap(createAccount);
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
          find.text('€42.50'),
          findsAtLeastNWidgets(2),
          reason: 'The balance should appear in the row and in the statement',
        );

        // The statistics destination opens the Mavio-style category report.
        await view.livePatch('/statistics');
        await _waitForUrl(tester, view, '/statistics', seconds: 30);
        await _waitFor(tester, find.text('Statistics'), seconds: 30);
        expect(find.text('Income and expenses'), findsOneWidget);

        final incomeExpenseCard = find.byType(Card).last;
        await tester.ensureVisible(incomeExpenseCard);
        await tester.tap(incomeExpenseCard);
        await _waitForUrl(
          tester,
          view,
          '/statistics/income-expense',
          seconds: 30,
        );
        await _waitFor(tester, find.text('This month'), seconds: 30);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(
          find.text('No transactions for this period'),
          findsOneWidget,
        );

        await tester.tap(find.byIcon(Icons.calendar_today));
        await _waitFor(
          tester,
          find.byType(LiveMonthPickerDrawer),
          seconds: 30,
        );
        expect(find.byType(BottomSheet), findsOneWidget);
        expect(find.text(DateTime.now().year.toString()), findsOneWidget);
        expect(find.byIcon(Icons.close), findsOneWidget);
        await tester.tap(find.byIcon(Icons.close));
        await _waitForAbsent(
          tester,
          find.byType(LiveMonthPickerDrawer),
          seconds: 30,
        );

        await view.livePatch('/');
        await _waitForUrl(tester, view, '/', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // The Home item opens the Mavio-style dashboard. It shows the total
        // statement, the income/expense chart, and the recent-expense state.
        final floatingButtonState = tester.state(
          find.byType(LiveFloatingActionButton),
        );
        await view.livePatch('/dashboard');
        await _waitForUrl(tester, view, '/dashboard', seconds: 30);
        await _waitFor(tester, find.text('Home'), seconds: 30);
        expect(
          tester.state(find.byType(LiveFloatingActionButton)),
          same(floatingButtonState),
          reason: 'the docked action must persist while navigating',
        );
        expect(find.text('Statement'), findsWidgets);
        expect(find.text('Income and expenses'), findsOneWidget);
        expect(find.byType(LiveBarChart), findsOneWidget);
        expect(find.text('Recent expenses'), findsOneWidget);
        expect(find.text('No expenses yet'), findsOneWidget);
        expect(find.text('€42.50'), findsWidgets);

        // Contacts use the same server-backed CRUD flow on Flutter.
        await view.livePatch('/contacts');
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('Contacts'), seconds: 30);
        expect(find.text('No contacts'), findsOneWidget);

        await view.livePatch('/contacts/new');
        await _waitForUrl(tester, view, '/contacts/new', seconds: 30);
        await _waitFor(tester, find.text('Add contact'), seconds: 30);
        final contactName = find.byType(TextField);
        expect(contactName, findsOneWidget);
        await tester.enterText(contactName, 'Alex Morgan');
        await tester.pump();
        final saveContact = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(saveContact.last);
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('Alex Morgan'), seconds: 30);

        // The edit page is part of the native contact flow as well.
        await tester.tap(find.text('Alex Morgan'));
        await _waitFor(tester, find.text('Edit contact'), seconds: 30);
        expect(view.currentUrl, matches(RegExp(r'^/contacts/\d+/edit$')));
        final editedContactName = find.byType(TextField);
        expect(editedContactName, findsOneWidget);
        await tester.enterText(editedContactName, 'Alex Martin');
        await tester.pump();
        await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ));
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('Alex Martin'), seconds: 30);

        // Lending uses the shared transaction form, requires a contact, and
        // updates that contact's running balance.
        await view.livePatch('/transactions/new?type=lent');
        await _waitForUrl(
          tester,
          view,
          '/transactions/new?type=lent',
          seconds: 30,
        );
        await _waitFor(tester, find.text('New transaction'), seconds: 30);

        final loanDropdowns = find.descendant(
          of: find.byType(Form),
          matching: find.byType(DropdownButton<String>),
        );
        expect(loanDropdowns, findsNWidgets(3));
        expect(find.text('Category'), findsNothing);

        await tester.tap(loanDropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alex Martin').last);
        await tester.pumpAndSettle();

        final loanFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(loanFields.at(0), '12.50');
        await tester.pump();
        await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ));
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);
        await tester.pump();

        await view.livePatch('/contacts');
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('Owes you'), seconds: 30);
        expect(find.text('€12.50'), findsOneWidget);

        // Borrowing is the opposite ledger direction. Borrowing €20 after
        // lending €12.50 leaves a net €7.50 owed to the contact.
        await view.livePatch('/transactions/new?type=borrowed');
        await _waitForUrl(
          tester,
          view,
          '/transactions/new?type=borrowed',
          seconds: 30,
        );
        await _waitFor(tester, find.text('New transaction'), seconds: 30);

        final borrowingDropdowns = find.descendant(
          of: find.byType(Form),
          matching: find.byType(DropdownButton<String>),
        );
        expect(borrowingDropdowns, findsNWidgets(3));
        expect(find.text('Category'), findsNothing);
        await tester.tap(borrowingDropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alex Martin').last);
        await tester.pumpAndSettle();

        final borrowingFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(borrowingFields.at(0), '20');
        await tester.pump();
        await tester.tap(find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        ));
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);
        await tester.pump();

        await view.livePatch('/contacts');
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('You owe'), seconds: 30);
        expect(find.text('€7.50'), findsOneWidget);

        // Return to accounts after exercising the dashboard route.
        await view.livePatch('/');
        await _waitForUrl(tester, view, '/', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // Mark the account inactive through the row overflow menu.
        final overflowMenu = find.byIcon(Icons.more_vert);
        await _waitFor(tester, overflowMenu, seconds: 30);
        await tester.tap(overflowMenu.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Mark as inactive'), seconds: 30);
        await tester.tap(find.text('Mark as inactive').last);
        await tester.pump();

        // The account leaves the active list and an inactive section appears.
        await _waitFor(tester, find.text('Inactive accounts (1)'), seconds: 30);
        expect(find.text('Integration account'), findsNothing);

        // Expanding the section shows the account again.
        await tester.tap(find.text('Inactive accounts (1)').last);
        await tester.pump();
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // The row overflow menu offers to mark it active again.
        final inactiveOverflowMenu = find.byIcon(Icons.more_vert);
        await _waitFor(tester, inactiveOverflowMenu, seconds: 30);
        await tester.tap(inactiveOverflowMenu.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Mark as active'), seconds: 30);
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

Future<void> _waitForAbsent(WidgetTester tester, Finder finder,
    {int seconds = 30}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (finder.evaluate().isEmpty) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder to disappear');
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
