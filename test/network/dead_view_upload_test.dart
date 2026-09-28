import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

// These are plain tests rather than testWidgets: deadViewUploadQuery awaits
// real dart:io file reads, which never complete inside testWidgets' fake
// async zone.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('dead-view-upload-test');
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  File uploadFixture() {
    return File('${tempDir.path}/upload.bin')
      ..writeAsBytesSync(utf8.encode('fake file content'));
  }

  test(
    'dead-view uploads send a multipart request with cookie and csrf',
    () async {
      var file = uploadFixture();

      var (view, server) = await connect(
        LiveView(),
        onRequest:
            (request) =>
                request.method == 'POST'
                    ? http.Response(
                      xmlCsrf,
                      200,
                      headers: {'set-cookie': 'live_view=refreshed'},
                    )
                    : null,
      );

      var response = await view.deadViewUploadQuery(
        '/upload',
        'file',
        file.path,
        formValues: {'extra': 'field'},
      );

      expect(response.statusCode, 200);

      var request = server.httpRequestsMade.lastWhere(
        (request) => request.method == 'POST',
      );
      expect(request.url.path, '/upload');
      expect(
        request.headers['content-type'],
        contains('multipart/form-data; boundary='),
      );
      expect(request.headers['cookie'], contains('live_view=session'));
      expect(request.headers['x-csrf-token'], 'csrf');

      var body = utf8.decode(request.bodyBytes);
      expect(
        body,
        contains('content-disposition: form-data; name="_csrf_token"'),
      );
      expect(body, contains('name="extra"'));
      expect(body, contains('field'));
      expect(body, contains('name="file"'));
      expect(body, contains('filename="upload.bin"'));
      expect(body, contains('fake file content'));
    },
  );

  test('dead-view uploads merge cookies from the response', () async {
    var (view, _) = await connect(
      LiveView(),
      onRequest:
          (request) =>
              request.method == 'POST'
                  ? http.Response(
                    xmlCsrf,
                    200,
                    headers: {'set-cookie': 'live_view=refreshed'},
                  )
                  : null,
    );

    expect(view.cookie, contains('live_view=session'));

    await view.deadViewUploadQuery('/upload', 'file', uploadFixture().path);

    expect(view.cookie, contains('live_view=refreshed'));
  });

  test('dead-view uploads follow redirects with a dead-view GET', () async {
    var (view, server) = await connect(
      LiveView(),
      onRequest: (request) {
        if (request.method == 'POST') {
          return http.Response('', 302, headers: {'location': '/accounts'});
        }
        return null;
      },
    );

    var response = await view.deadViewUploadQuery(
      '/upload',
      'file',
      uploadFixture().path,
    );

    expect(response.statusCode, 302);
    var requests = server.httpRequestsMade;
    var postIndex = requests.lastIndexWhere((r) => r.method == 'POST');
    var followUp = requests.sublist(postIndex + 1);
    expect(
      followUp.any((r) => r.method == 'GET' && r.url.path == '/accounts'),
      isTrue,
    );
  });
}
