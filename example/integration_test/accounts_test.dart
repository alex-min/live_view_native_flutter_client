import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:liveview_flutter/live_view/ui/components/live_balance_chart.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_infinite_list.dart';
import 'package:liveview_flutter/live_view/ui/components/live_month_picker_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_segmented_progress_bar.dart';
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
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Empty state: no accounts yet, with a create button and no
        // overview figures (the merged overview only shows with accounts).
        await _waitFor(tester, find.text('No accounts yet'), seconds: 30);
        expect(find.text('Total'), findsNothing);
        expect(find.text('Available'), findsNothing);
        expect(find.text('Saved'), findsNothing);

        // Open the creation form.
        final addAccount = find.widgetWithText(
          ElevatedButton,
          'Create an account',
        );
        await _waitFor(tester, addAccount.hitTestable(), seconds: 30);
        await tester.tap(addAccount.hitTestable().last);
        await _waitForUrl(tester, view, '/accounts/new', seconds: 30);

        // Account creation starts by choosing who manages the account.
        // Automated accounts are gated behind Pro, so this test exercises
        // the manual flow directly.
        await _waitFor(tester, find.text('Automated'), seconds: 30);
        expect(find.text('Manual'), findsOneWidget);

        await view.livePatch('/accounts/new/manual');
        await _waitForUrl(tester, view, '/accounts/new/manual', seconds: 30);

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
        expect(find.byIcon(Icons.payments), findsOneWidget);
        final accountsCard =
            find
                .ancestor(
                  of: find.text('Your accounts'),
                  matching: find.byType(Card),
                )
                .hitTestable();
        expect(accountsCard, findsOneWidget);
        final accountsRect = tester.getRect(accountsCard);
        final scaffoldWidth = tester.getSize(find.byType(Scaffold).first).width;
        expect(accountsRect.left, 0);
        expect(accountsRect.right, scaffoldWidth);
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

        await view.livePatch('/statistics/income-expense');
        await _waitForUrl(
          tester,
          view,
          '/statistics/income-expense',
          seconds: 30,
        );
        await _waitFor(tester, find.text('This month'), seconds: 30);
        expect(find.text('Income'), findsOneWidget);
        expect(find.text('Expenses'), findsOneWidget);
        expect(find.text('No transactions for this period'), findsOneWidget);

        await tester.tap(find.byIcon(Icons.calendar_today));
        await _waitFor(tester, find.byType(LiveMonthPickerDrawer), seconds: 30);
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
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // The Home item opens the dashboard, matching the mobile web home:
        // a statement card, the income/expense summary, and the empty
        // recent-expense state.
        final floatingButtonState = tester.state(
          find.byType(LiveFloatingActionButton),
        );
        await view.livePatch('/dashboard');
        await _waitForUrl(tester, view, '/dashboard', seconds: 30);
        await _waitFor(tester, find.text('Statement'), seconds: 30);
        expect(
          tester.state(find.byType(LiveFloatingActionButton)),
          same(floatingButtonState),
          reason: 'the docked action must persist while navigating',
        );
        expect(find.text('Net this month'), findsOneWidget);
        expect(find.text('INCOME'), findsOneWidget);
        expect(find.text('EXPENSES'), findsOneWidget);
        expect(find.text('Monthly flow'), findsOneWidget);
        expect(find.text('Statistics'), findsOneWidget);
        expect(find.byType(LiveCosmicBackground), findsWidgets);
        expect(find.text('RECENT EXPENSES'), findsOneWidget);
        expect(find.text('View all'), findsOneWidget);
        expect(find.text('€42.50'), findsWidgets);
        // The old Mavio-style home is gone: no quick actions, no fake chart,
        // no balance eye toggle.
        expect(find.text('Send'), findsNothing);
        expect(find.text('Trends'), findsNothing);
        expect(find.text('Money activity'), findsNothing);
        expect(find.text('••••••'), findsNothing);
        await tester.drag(find.byType(ListView).last, const Offset(0, -300));
        await tester.pump();
        expect(find.text('No expenses yet'), findsOneWidget);

        // Contacts use the same server-backed CRUD flow on Flutter.
        await view.livePatch('/contacts');
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('Contacts'), seconds: 30);
        expect(find.text('No contacts').hitTestable(), findsOneWidget);

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
        await tester.tap(find.text('Alex Morgan').last);
        await _waitFor(tester, find.text('Edit contact'), seconds: 30);
        expect(view.currentUrl, matches(RegExp(r'^/contacts/\d+/edit$')));
        final editedContactName = find.byType(TextField).hitTestable();
        expect(editedContactName, findsOneWidget);
        await tester.enterText(editedContactName, 'Alex Martin');
        await tester.pump();
        await tester.tap(
          find
              .descendant(
                of: find.byType(Form),
                matching: find.byType(ElevatedButton),
              )
              .last,
        );
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
        expect(loanDropdowns, findsNWidgets(2));
        expect(find.text('Category'), findsNothing);

        await tester.tap(loanDropdowns.at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alex Martin').last);
        await tester.pumpAndSettle();

        final loanFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(loanFields.at(0), '12.50');
        await tester.pump();
        final saveButton =
            find
                .descendant(
                  of: find.byType(Form),
                  matching: find.byType(ElevatedButton),
                )
                .first;
        // The docked close bar can overlap the button at small window
        // heights; scroll it fully into view before tapping.
        await tester.ensureVisible(saveButton);
        await tester.tap(saveButton);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions\?focus_transaction_id=\d+$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Integration account'), seconds: 30);
        await tester.pump();

        // The combined transaction screen is the second navigation
        // destination and includes the source account on every row.
        await view.livePatch('/transactions');
        await _waitForUrl(tester, view, '/transactions', seconds: 30);
        await _waitFor(tester, find.text('Money activity'), seconds: 30);
        expect(find.text('Net activity this month'), findsOneWidget);
        expect(find.text('Income minus expenses'), findsOneWidget);
        expect(find.text('Search transactions'), findsOneWidget);
        expect(
          find
              .byKey(const ValueKey('balance_chart_search_button'))
              .hitTestable(),
          findsOneWidget,
        );
        expect(
          find.byType(LiveBalanceChart).hitTestable().last,
          findsOneWidget,
        );
        final activityScroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .hitTestable()
              .first,
        );
        activityScroll.position.jumpTo(600);
        await tester.pump();
        expect(find.text('Money activity').hitTestable(), findsOneWidget);
        final compactSearchButton =
            find
                .byKey(const ValueKey('balance_chart_search_button'))
                .hitTestable()
                .last;
        expect(compactSearchButton.hitTestable(), findsOneWidget);
        await tester.tap(compactSearchButton);
        await tester.pumpAndSettle();
        final transactionSearch = find.descendant(
          of: find.byType(LiveBalanceChart).hitTestable().last,
          matching: find.byType(TextField),
        );
        expect(transactionSearch, findsOneWidget);
        await _waitFor(tester, find.text('Lent to Alex Martin'), seconds: 30);
        expect(find.text('Lent to Alex Martin'), findsOneWidget);
        expect(find.textContaining('Integration account'), findsWidgets);

        expect(transactionSearch, findsOneWidget);
        await tester.enterText(transactionSearch, 'no matching transaction');
        await _waitForAbsent(tester, find.text('Lent to Alex Martin'));
        await tester.enterText(transactionSearch, 'Alex Martin');
        await _waitFor(tester, find.text('Lent to Alex Martin'));

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
        expect(borrowingDropdowns, findsNWidgets(2));
        expect(find.text('Category'), findsNothing);
        await tester.tap(borrowingDropdowns.at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Alex Martin').last);
        await tester.pumpAndSettle();

        final borrowingFields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(borrowingFields.at(0), '20');
        await tester.pump();
        final loanSaveButton =
            find
                .descendant(
                  of: find.byType(Form),
                  matching: find.byType(ElevatedButton),
                )
                .first;
        // The docked close bar can overlap the button at small window
        // heights; scroll it fully into view before tapping.
        await tester.ensureVisible(loanSaveButton);
        await tester.tap(loanSaveButton);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions\?focus_transaction_id=\d+$'),
          seconds: 30,
        );
        await _waitFor(tester, find.text('Integration account'), seconds: 30);
        await tester.pump();

        await view.livePatch('/contacts');
        await _waitForUrl(tester, view, '/contacts', seconds: 30);
        await _waitFor(tester, find.text('You owe'), seconds: 30);
        expect(find.text('€7.50'), findsOneWidget);

        // Return to accounts after exercising the dashboard route.
        await view.livePatch('/');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // Mark the account inactive through the row overflow menu.
        final overflowMenu = find.byIcon(Icons.more_vert);
        await _waitFor(tester, overflowMenu, seconds: 30);
        await tester.tap(overflowMenu.last);
        await tester.pumpAndSettle();
        await _waitFor(tester, find.text('Mark as inactive'), seconds: 30);
        final markInactive = find.text('Mark as inactive').last;
        await tester.ensureVisible(markInactive);
        await tester.tap(markInactive, warnIfMissed: true);
        await tester.pumpAndSettle();

        // The account leaves the active list and an inactive section appears.
        await _waitFor(tester, find.text('Inactive accounts (1)'), seconds: 30);
        expect(find.text('Integration account'), findsNothing);

        // Expanding the section shows the account again.
        await tester.tap(find.text('Inactive accounts (1)').last);
        await tester.pump();
        await _waitFor(tester, find.text('Integration account'), seconds: 30);

        // The row overflow menu offers to mark it active again, inline in
        // the inactive row like the web view.
        await _waitFor(tester, find.text('Mark as active'), seconds: 30);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'loads arbitrary transaction chunks and survives repeated deletes',
      (tester) async {
        await _ensureServer();
        SharedPreferences.setMockInitialValues({});
        final view = LiveView();
        view.catchExceptions = false;
        view.disableAnimations = false;
        view.throttleSpammyCalls = false;

        await tester.pumpWidget(_TestApp(view: view));
        await view.connect('http://$_serverHost:$_serverPort/');
        await _signUpAndOnboard(tester, view);

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        final tryDemoFinder = find.widgetWithText(ElevatedButton, 'Try demo');
        await _waitFor(tester, tryDemoFinder, seconds: 30);
        await tester.ensureVisible(tryDemoFinder.last);
        await tester.drag(
          find.byType(ListView).hitTestable().last,
          const Offset(0, -100),
        );
        await tester.pump();
        await tester.tap(tryDemoFinder.last.hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        // Rows build lazily: scroll until the Cash row enters the viewport.
        // The previous accounts route stays mounted underneath, so scope the
        // finders to the visible list.
        final visibleList = find.byType(ListView).hitTestable().last;
        final cashTile = find.descendant(
          of: visibleList,
          matching: find.text('Cash'),
        );
        await tester.scrollUntilVisible(
          cashTile,
          80,
          scrollable: find.descendant(
            of: visibleList,
            matching: find.byType(Scrollable),
          ),
        );
        final cashAccount = cashTile.hitTestable();
        if (cashAccount.evaluate().isEmpty) {
          // The row can sit under the docked action button; nudge the list
          // so it is fully tappable.
          await tester.drag(visibleList, const Offset(0, -200));
          await tester.pump();
        }
        final visibleCashAccount =
            find
                .descendant(of: visibleList, matching: find.text('Cash'))
                .hitTestable();
        await _waitFor(tester, visibleCashAccount, seconds: 30);
        await tester.tap(visibleCashAccount);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(tester, find.byType(LiveInfiniteList), seconds: 30);

        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });
        await tester.pumpAndSettle();

        expect(find.byKey(const Key('main_app_bar')), findsNothing);
        expect(find.byType(BottomNavigationBar), findsOneWidget);
        expect(
          find.byType(LiveBalanceChart).hitTestable().last,
          findsOneWidget,
        );
        expect(find.text('AVAILABLE BALANCE'), findsOneWidget);

        final balancePainter =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is BalanceHistoryPainter,
                      ),
                    )
                    .painter!
                as BalanceHistoryPainter;
        expect(balancePainter.points.length, greaterThan(1));
        expect(balancePainter.directions.last, 'current');
        expect(balancePainter.labels.last, contains('\n'));
        final initialSelectedPoint = balancePainter.selectedIndex;

        final transactionRows = find.descendant(
          of: find.byType(LiveInfiniteList),
          matching: find.byType(ListTile),
        );
        expect(transactionRows.evaluate().length, inInclusiveRange(1, 20));

        final pinnedHeader = tester.widget<SliverPersistentHeader>(
          find.descendant(
            of: find.byType(LiveInfiniteList),
            matching: find.byType(SliverPersistentHeader),
          ),
        );
        final headerDelegate =
            pinnedHeader.delegate as CollapsibleInfiniteListHeaderDelegate;
        expect(pinnedHeader.pinned, isTrue);
        expect(headerDelegate.maxExtent, 430);
        expect(headerDelegate.minExtent, 120);

        final collapsibleScroll = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(CustomScrollView),
                matching: find.byType(Scrollable),
              )
              .hitTestable()
              .first,
        );
        collapsibleScroll.position.jumpTo(334);
        await tester.pumpAndSettle();
        expect(collapsibleScroll.position.pixels, 334);
        expect(
          find.descendant(
            of: find.byType(LiveBalanceChart).hitTestable().last,
            matching: find.text('Cash').hitTestable(),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(LiveBalanceChart).hitTestable().last,
            matching:
                find
                    .byKey(const ValueKey('balance_chart_search_button'))
                    .hitTestable(),
          ),
          findsOneWidget,
        );
        await tester.tap(
          find.byKey(const ValueKey('balance_chart_search_button')),
        );
        await tester.pumpAndSettle();
        expect(
          find.descendant(
            of: find.byType(LiveBalanceChart).hitTestable().last,
            matching: find.byType(EditableText).hitTestable(),
          ),
          findsOneWidget,
        );
        FocusManager.instance.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(find.byType(TextField), findsNothing);
        final scrolledBalancePainter =
            tester
                    .widget<CustomPaint>(
                      find.byWidgetPredicate(
                        (widget) =>
                            widget is CustomPaint &&
                            widget.painter is BalanceHistoryPainter,
                      ),
                    )
                    .painter!
                as BalanceHistoryPainter;
        expect(scrolledBalancePainter.selectedIndex, initialSelectedPoint);
        expect(
          tester.getSize(
            find
                .descendant(
                  of: find.byType(SliverPersistentHeader),
                  matching: find.byType(ClipRect),
                )
                .first,
          ),
          const Size(400, 120),
        );
        expect(find.text('Load more'), findsNothing);

        final scrollable = collapsibleScroll;
        final fullExtent = scrollable.position.maxScrollExtent;
        expect(fullExtent, greaterThan(40 * 64 * 5));

        final deepChartWindows = <String>{};
        for (var jump = 0; jump < 12; jump++) {
          final target = fullExtent * (jump.isEven ? 0.3 : 0.7);
          scrollable.position.jumpTo(target);
          await tester.pump();
          await _waitFor(tester, transactionRows.hitTestable(), seconds: 30);

          expect(transactionRows.evaluate().length, inInclusiveRange(1, 20));
          expect(scrollable.position.maxScrollExtent, closeTo(fullExtent, 1));
          expect(scrollable.position.pixels, closeTo(target, 1));
          final deepPainter =
              tester
                      .widget<CustomPaint>(
                        find.byWidgetPredicate(
                          (widget) =>
                              widget is CustomPaint &&
                              widget.painter is BalanceHistoryPainter,
                        ),
                      )
                      .painter!
                  as BalanceHistoryPainter;
          expect(deepPainter.points.length, lessThanOrEqualTo(80));
          expect(deepPainter.selectedIndex, inInclusiveRange(10, 70));
          deepChartWindows.add(deepPainter.points.join(','));
        }
        expect(deepChartWindows.length, greaterThan(1));

        var positionBeforeEdit = scrollable.position.pixels;
        await tester.tap(transactionRows.hitTestable().first);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );

        final closeButton = find.byIcon(Icons.close).hitTestable();
        await _waitFor(tester, closeButton, seconds: 30);
        await tester.tap(closeButton);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/accounts/\d+/transactions$'),
          seconds: 30,
        );
        await _waitFor(tester, find.byType(LiveInfiniteList), seconds: 30);
        expect(find.byType(LiveInfiniteList), findsWidgets);

        final listAfterClose =
            find
                .descendant(
                  of: find.byType(CustomScrollView),
                  matching: find.byWidgetPredicate(
                    (widget) =>
                        widget is Scrollable &&
                        widget.axisDirection == AxisDirection.down,
                  ),
                )
                .hitTestable();
        expect(listAfterClose, findsOneWidget);
        final scrollableAfterClose = tester.state<ScrollableState>(
          listAfterClose,
        );
        final extentAfterClose = scrollableAfterClose.position.maxScrollExtent;
        expect(extentAfterClose, closeTo(fullExtent, 1));

        final offsetBeforeDrag = scrollableAfterClose.position.pixels;
        await tester.drag(listAfterClose, const Offset(0, -300));
        await tester.pumpAndSettle();
        expect(
          scrollableAfterClose.position.pixels,
          greaterThan(offsetBeforeDrag),
          reason: 'The restored transaction list must remain draggable',
        );

        for (final fraction in [0.2, 0.8, 0.35, 0.65]) {
          final target = extentAfterClose * fraction;
          scrollableAfterClose.position.jumpTo(target);
          await tester.pump();
          await _waitFor(tester, transactionRows.hitTestable(), seconds: 30);
          expect(scrollableAfterClose.position.pixels, closeTo(target, 1));
        }

        positionBeforeEdit = scrollableAfterClose.position.pixels;
        await tester.tap(transactionRows.hitTestable().first);
        await _waitForUrl(
          tester,
          view,
          RegExp(r'^/transactions/\d+/edit$'),
          seconds: 30,
        );

        for (var deletion = 0; deletion < 2; deletion++) {
          final deleteButton = find.widgetWithText(OutlinedButton, 'Delete');
          await _waitFor(tester, deleteButton, seconds: 30);
          await tester.ensureVisible(deleteButton);
          await tester.tap(deleteButton);
          await _waitFor(tester, find.byType(AlertDialog), seconds: 30);
          await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
          await _waitForUrl(
            tester,
            view,
            RegExp(r'^/accounts/\d+/transactions$'),
            seconds: 30,
          );
          await _waitFor(tester, find.byType(LiveInfiniteList), seconds: 30);

          final restoredList =
              find
                  .descendant(
                    of: find.byType(LiveInfiniteList),
                    matching: find.byType(Scrollable),
                  )
                  .hitTestable()
                  .first;
          final restoredScrollable = tester.state<ScrollableState>(
            restoredList,
          );
          expect(
            restoredScrollable.position.pixels,
            closeTo(positionBeforeEdit, 1),
            reason: 'Deleting a transaction should preserve the list position',
          );

          if (deletion == 0) {
            final returnedRows = find.descendant(
              of: find.byType(LiveInfiniteList),
              matching: find.byType(ListTile),
            );
            final returnedList =
                find
                    .descendant(
                      of: find.byType(LiveInfiniteList),
                      matching: find.byType(Scrollable),
                    )
                    .hitTestable()
                    .first;
            final returnedScrollable = tester.state<ScrollableState>(
              returnedList,
            );
            final returnedExtent = returnedScrollable.position.maxScrollExtent;

            for (var jump = 0; jump < 4; jump++) {
              returnedScrollable.position.jumpTo(
                returnedExtent * (jump.isEven ? 0.35 : 0.65),
              );
              await tester.pump();
              await _waitFor(tester, returnedRows.hitTestable(), seconds: 30);
            }

            positionBeforeEdit = returnedScrollable.position.pixels;
            await tester.tap(returnedRows.hitTestable().first);
            await _waitForUrl(
              tester,
              view,
              RegExp(r'^/transactions/\d+/edit$'),
              seconds: 30,
            );
          }
        }
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'scrolls the account list like the mobile web page',
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

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        // Seed demo accounts so the list has rows to scroll.
        final tryDemoFinder = find.widgetWithText(ElevatedButton, 'Try demo');
        await _waitFor(tester, tryDemoFinder, seconds: 30);
        await tester.ensureVisible(tryDemoFinder.last);
        await tester.drag(
          find.byType(ListView).hitTestable().last,
          const Offset(0, -100),
        );
        await tester.pump();
        await tester.tap(tryDemoFinder.last.hitTestable());
        await _waitForUrl(tester, view, '/accounts', seconds: 30);

        await view.livePatch('/accounts');
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        // The merged overview and the filter pills render above the list.
        await _waitFor(tester, find.text('Stock picks'), seconds: 30);
        expect(find.text('Total').hitTestable(), findsOneWidget);
        expect(find.text('All').hitTestable(), findsOneWidget);

        // The whole page scrolls away like mobile web: no pinned header.
        final scrollable = tester.state<ScrollableState>(
          find
              .descendant(
                of: find.byType(ListView).hitTestable().last,
                matching: find.byType(Scrollable),
              )
              .first,
        );
        scrollable.position.jumpTo(500);
        await tester.pump();
        expect(
          find.text('Total').hitTestable(),
          findsNothing,
          reason: 'Scrolling should move the overview out of view',
        );
        await tester.scrollUntilVisible(
          find.text('Stock picks').last,
          120,
          scrollable:
              find
                  .descendant(
                    of: find.byType(ListView).hitTestable().last,
                    matching: find.byType(Scrollable),
                  )
                  .first,
        );
        expect(
          find.text('Stock picks').hitTestable(),
          findsWidgets,
          reason: 'The account rows should stay visible while scrolled',
        );

        scrollable.position.jumpTo(0);
        await tester.pump();
        expect(
          find.text('Total').hitTestable(),
          findsOneWidget,
          reason: 'Scrolling back to the top should restore the overview',
        );
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'creates an investment account with an investment kind',
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

        await view.livePatch('/accounts/new/manual');
        await _waitForUrl(tester, view, '/accounts/new/manual', seconds: 30);

        // Until "Investment" is picked, the only dropdown is the account
        // type one; the currency field is a CurrencyInput, not a dropdown.
        final formDropdowns = find.descendant(
          of: find.byType(Form),
          matching: find.byType(DropdownButton<String>),
        );
        await _waitFor(tester, formDropdowns, seconds: 30);
        expect(formDropdowns, findsOneWidget);

        await tester.tap(formDropdowns);
        await tester.pumpAndSettle();
        await tester.tap(find.text('Investment').last);
        await tester.pumpAndSettle();

        // Picking "Investment" reveals the investment kind dropdown.
        await _waitFor(tester, formDropdowns, seconds: 30);
        expect(formDropdowns, findsNWidgets(2));

        final fields = find.descendant(
          of: find.byType(Form),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), '1.25');
        await tester.pump();
        await tester.enterText(fields.at(1), 'Bitcoin vault');
        await tester.pump();

        await tester.tap(formDropdowns.at(1));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Crypto').last);
        await tester.pumpAndSettle();

        // The server sends validate diffs that can reset field controllers,
        // so refill right before submitting (same workaround as the manual
        // account creation test above).
        await Future.delayed(const Duration(seconds: 1));
        await tester.pump();
        await tester.enterText(fields.at(0), '1.25');
        await tester.pump();
        await tester.enterText(fields.at(1), 'Bitcoin vault');
        await tester.pump();

        final submitButton = find.descendant(
          of: find.byType(Form),
          matching: find.byType(ElevatedButton),
        );
        await tester.tap(submitButton);

        // Back on the list, the account appears with its investment kind
        // shown in the row subtitle.
        await _waitForUrl(tester, view, '/accounts', seconds: 30);
        await _waitFor(tester, find.text('Bitcoin vault'), seconds: 30);
        expect(find.text('Crypto'), findsWidgets);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

/// Signs up a brand new user and completes the onboarding (TOS + default
/// currency). Mirrors the onboarding flow integration test.
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

  // Onboarding completes on the last currency step and redirects to the
  // accounts page (which has a compact app bar, so the email never shows).
  await _waitForUrl(tester, view, '/accounts', seconds: 30);
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
    if (find
        .text('Unable to parse the Flutter live view data')
        .evaluate()
        .isNotEmpty) {
      throw Exception('LiveView XML failed to parse. ${_visibleText()}');
    }
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(seconds: 1));
  }
  throw Exception('Timed out waiting for $finder. ${_visibleText()}');
}

String _visibleText() {
  final visibleText = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .take(20)
      .join(' | ');
  return 'Visible text: $visibleText';
}

Future<void> _waitForAbsent(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
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
Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  Object url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds; i++) {
    await tester.pump();
    if (view.isCurrentRouteReady &&
        ((url is String && view.currentUrl == url) ||
            (url is RegExp && url.hasMatch(view.currentUrl)))) {
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
