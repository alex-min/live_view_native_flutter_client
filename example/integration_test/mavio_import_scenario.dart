import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:liveview_flutter/liveview_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

const _serverHost = 'localhost';
const _serverPort = 4000;

const _email = 'mavio_test@example.com';
const _password = 'password123456';

class _TestApp extends StatelessWidget {
  const _TestApp({required this.view});

  final LiveView view;

  @override
  Widget build(BuildContext context) => view.rootView;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(_ensureServer);
  // sqflite has no Linux plugin; the ffi factory mirrors what the
  // MavioImportButton locator does on desktop.
  databaseFactory = databaseFactoryFfi;

  testWidgets('Mavio import page: not-found state then successful import', (
    tester,
  ) async {
    final view = LiveView()
      ..catchExceptions = false
      ..disableAnimations = true
      ..throttleSpammyCalls = false;
    addTearDown(view.disconnect);

    await tester.pumpWidget(_TestApp(view: view));
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Make sure no legacy database is present so the not-found state shows.
    final dbDir = await getDatabasesPath();
    final dbPath = p.join(dbDir, 'app_database8.db');
    final dbFile = File(dbPath);
    if (dbFile.existsSync()) {
      dbFile.deleteSync();
    }

    // Sign in through the real login form unless a persisted session
    // already redirected us to the accounts page.
    await view.connect('http://$_serverHost:$_serverPort/users/log_in');
    await tester.pumpAndSettle();
    if (Uri.tryParse(view.currentUrl)?.path == '/users/log_in') {
      await _waitFor(tester, find.byType(TextField), seconds: 15);
      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), _email);
      await tester.pump();
      await tester.enterText(fields.at(1), _password);
      await tester.pump();
      final signInButton = find.widgetWithText(ElevatedButton, 'Sign in');
      await tester.tap(signInButton);
    }
    await _waitForUrl(tester, view, '/accounts', seconds: 15);

    // Open the settings page and tap the Mavio row.
    await view.livePatch('/users/settings');
    await _waitForUrl(tester, view, '/users/settings', seconds: 15);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Mavio'), seconds: 15);
    final mavioRow = find.text('Mavio').last;
    await tester.ensureVisible(mavioRow);
    await tester.pumpAndSettle();
    await tester.tap(mavioRow);
    await _waitForUrl(tester, view, '/settings/import/mavio', seconds: 15);
    await tester.pumpAndSettle();

    // The flutter variant renders the title, explanation and both actions.
    expect(find.text('Import from Mavio'), findsOneWidget);
    expect(
      find.textContaining('The old Mavio app database is still on this device'),
      findsOneWidget,
    );
    expect(find.text('Import my old data'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Without a legacy database the button reports the not-found state.
    final importButton = find.widgetWithText(
      ElevatedButton,
      'Import my old data',
    );
    await tester.tap(importButton);
    await _waitFor(
      tester,
      find.text('No Mavio database was found on this device.'),
      seconds: 10,
    );

    // Drop a valid Mavio database where the legacy app would have left it.
    await _writeMavioFixture(dbPath);
    addTearDown(() {
      if (dbFile.existsSync()) {
        dbFile.deleteSync();
      }
    });

    // Importing uploads the database and lands back on the accounts page,
    // where the imported account is listed.
    await tester.tap(importButton);
    await _waitForUrl(tester, view, '/accounts', seconds: 15);
    await tester.pumpAndSettle();
    await _waitFor(tester, find.text('Wallet'), seconds: 15);
    expect(find.text('Wallet'), findsWidgets);

    // The import summary flash survives the redirect to /accounts.
    await _waitFor(
      tester,
      find.textContaining('Mavio import complete'),
      seconds: 15,
    );
    expect(find.textContaining('Mavio import complete'), findsOneWidget);
  });
}

Future<void> _writeMavioFixture(String path) async {
  final db = await openDatabase(path);
  await db.execute('''
    CREATE TABLE Account (
      name TEXT, description TEXT, accountType TEXT, currency TEXT,
      initialBalanceCents INTEGER, createdAt TEXT, id TEXT PRIMARY KEY,
      sortOrder INTEGER, inactive INTEGER, deletedAt TEXT
    );
    CREATE TABLE CustomCategory (
      name TEXT, id TEXT PRIMARY KEY, isSystem INTEGER, strType TEXT,
      parentId TEXT, customIcon TEXT, deletedAt TEXT, color TEXT
    );
    CREATE TABLE Reference (
      id TEXT PRIMARY KEY, name TEXT, deletedAt TEXT
    );
    CREATE TABLE Ledger (
      amountCents INTEGER, accountId TEXT, description TEXT, category TEXT,
      categoryParent TEXT, createdAt TEXT, id TEXT PRIMARY KEY, spentAt TEXT,
      type TEXT, accountTransferTo TEXT, transferTransactionId TEXT,
      deletedAt TEXT, referenceId TEXT, amountAdjustedCents INTEGER
    );

    INSERT INTO Account VALUES
      ('Wallet', 'Everyday cash', 'cash', 'EUR', 12345, '2024-01-01T00:00:00Z', 'wallet', 3, 0, NULL);
    INSERT INTO CustomCategory VALUES
      ('groceries', 'system-groceries', 1, 'expense', 'food', NULL, NULL, NULL);
    INSERT INTO Ledger VALUES
      (-1250, 'wallet', 'Market', 'system-groceries', NULL, '2024-01-02T10:00:00Z', 'expense', '2024-01-02T10:00:00Z', 'expense', NULL, NULL, NULL, NULL, NULL);
  ''');
  await db.close();
}

Future<void> _waitFor(
  WidgetTester tester,
  Finder finder, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await tester.pump();
    if (finder.evaluate().isNotEmpty) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for $finder');
}

Future<void> _waitForUrl(
  WidgetTester tester,
  LiveView view,
  String url, {
  int seconds = 30,
}) async {
  for (var i = 0; i < seconds * 5; i++) {
    await tester.pump();
    final currentPath = Uri.tryParse(view.currentUrl)?.path ?? '';
    if (currentPath == url && view.isCurrentRouteReady) {
      return;
    }
    await Future.delayed(const Duration(milliseconds: 200));
  }
  throw Exception('Timed out waiting for url $url (got ${view.currentUrl})');
}

Future<void> _ensureServer() async {
  final socket = await Socket.connect(
    _serverHost,
    _serverPort,
    timeout: const Duration(seconds: 2),
  );
  await socket.close();
}
