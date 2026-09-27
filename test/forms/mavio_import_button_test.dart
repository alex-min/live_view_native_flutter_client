import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_mavio_import_button.dart';

import '../test_helpers.dart';

class FakeMavioDatabaseLocator implements MavioDatabaseLocator {
  FakeMavioDatabaseLocator({this.path});

  final String? path;
  String? databaseName;

  @override
  Future<String?> locate(String databaseName) async {
    this.databaseName = databaseName;
    return path;
  }
}

void main() {
  late MavioDatabaseLocator originalLocator;
  late Directory tempDir;

  setUp(() {
    originalLocator = MavioImportService.locator;
    tempDir = Directory.systemTemp.createTempSync('mavio-import-button-test');
  });

  tearDown(() {
    MavioImportService.locator = originalLocator;
    tempDir.deleteSync(recursive: true);
  });

  testWidgets('uploads the located Mavio database to the configured action', (
    tester,
  ) async {
    var file = File('${tempDir.path}/app_database8.db')
      ..writeAsBytesSync(utf8.encode('old-mavio-db-bytes'));
    var locator = FakeMavioDatabaseLocator(path: file.path);
    MavioImportService.locator = locator;

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<MavioImportButton action="/settings/import/mavio" field="mavio[database]" databaseName="app_database8.db" label="Import my old data" />',
        ],
      },
      onRequest:
          (request) =>
              request.method == 'POST'
                  ? http.Response('', 302, headers: {'location': '/accounts'})
                  : null,
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    // deadViewUploadQuery awaits real dart:io file reads, which never
    // complete inside testWidgets' fake async zone; runAsync gives them a
    // real event loop.
    await tester.runAsync(() async {
      await tester.tap(find.byType(ElevatedButton));
      await Future<void>.delayed(const Duration(milliseconds: 100));
    });
    await tester.pumpAndSettle();

    expect(locator.databaseName, 'app_database8.db');

    var request = server.httpRequestsMade.lastWhere(
      (request) => request.method == 'POST',
    );
    expect(request.url.path, '/settings/import/mavio');
    expect(
      request.headers['content-type'],
      contains('multipart/form-data; boundary='),
    );
    var body = utf8.decode(request.bodyBytes);
    expect(body, contains('name="mavio[database]"'));
    expect(body, contains('old-mavio-db-bytes'));
    expect(body, contains('name="_csrf_token"'));
  });

  testWidgets('shows the not-found label when no database is on the device', (
    tester,
  ) async {
    MavioImportService.locator = FakeMavioDatabaseLocator(path: null);

    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<MavioImportButton notFoundLabel="No Mavio database found on this device." />',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    expect(
      find.text('No Mavio database found on this device.'),
      findsOneWidget,
    );
  });
}
