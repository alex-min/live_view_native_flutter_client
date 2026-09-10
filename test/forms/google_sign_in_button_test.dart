import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_google_sign_in_button.dart';

import '../test_helpers.dart';

class FakeGoogleAuthenticator implements GoogleAuthenticator {
  FakeGoogleAuthenticator({this.token, this.error});

  final String? token;
  final Object? error;
  String? clientId;
  String? serverClientId;

  @override
  Future<String?> authenticate({
    String? clientId,
    String? serverClientId,
  }) async {
    this.clientId = clientId;
    this.serverClientId = serverClientId;
    if (error != null) throw error!;
    return token;
  }
}

void main() {
  late GoogleAuthenticator originalAuthenticator;

  setUp(() {
    originalAuthenticator = GoogleSignInService.authenticator;
  });

  tearDown(() {
    GoogleSignInService.authenticator = originalAuthenticator;
  });

  testWidgets('posts a Google ID token to the configured action', (
    tester,
  ) async {
    var authenticator = FakeGoogleAuthenticator(token: 'google-id-token');
    GoogleSignInService.authenticator = authenticator;

    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<GoogleSignInButton action="/users/auth/google/native" clientId="ios-id" serverClientId="web-id" label="Continue with Google" />',
        ],
      },
      onRequest:
          (request) =>
              request.method == 'POST'
                  ? http.Response('', 302, headers: {'location': '/'})
                  : null,
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    var request = server.httpRequestsMade.lastWhere(
      (request) => request.method == 'POST',
    );
    expect(request.method, 'POST');
    expect(request.url.path, '/users/auth/google/native');
    expect(request.body, 'id_token=google-id-token&_csrf_token=csrf');
    expect(authenticator.clientId, 'ios-id');
    expect(authenticator.serverClientId, 'web-id');
  });

  testWidgets('shows a server-provided error label when Google sign-in fails', (
    tester,
  ) async {
    GoogleSignInService.authenticator = FakeGoogleAuthenticator(
      error: StateError('cancelled'),
    );
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          '<GoogleSignInButton label="Continue with Google" errorLabel="Unable to sign in" />',
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();
    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(find.text('Unable to sign in'), findsOneWidget);
  });
}
