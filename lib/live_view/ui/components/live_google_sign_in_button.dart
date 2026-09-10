import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

abstract interface class GoogleAuthenticator {
  Future<String?> authenticate({String? clientId, String? serverClientId});
}

class PlatformGoogleAuthenticator implements GoogleAuthenticator {
  bool _initialized = false;

  @override
  Future<String?> authenticate({
    String? clientId,
    String? serverClientId,
  }) async {
    var google = GoogleSignIn.instance;
    if (!_initialized) {
      await google.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );
      _initialized = true;
    }
    if (!google.supportsAuthenticate()) {
      throw UnsupportedError('Google Sign-In is unavailable on this platform');
    }
    var account = await google.authenticate();
    return account.authentication.idToken;
  }
}

class GoogleSignInService {
  GoogleSignInService._();

  static GoogleAuthenticator authenticator = PlatformGoogleAuthenticator();
}

class LiveGoogleSignInButton extends LiveStateWidget<LiveGoogleSignInButton> {
  const LiveGoogleSignInButton({super.key, required super.state});

  @override
  State<LiveGoogleSignInButton> createState() => _LiveGoogleSignInButtonState();
}

class _LiveGoogleSignInButtonState extends StateWidget<LiveGoogleSignInButton> {
  bool _loading = false;
  bool _failed = false;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, [
      'action',
      'clientId',
      'serverClientId',
      'label',
      'errorLabel',
    ]);
  }

  @override
  HandleClickState handleClickState() => HandleClickState.manual;

  String? _optionalAttribute(String name) {
    var value = getAttribute(name);
    return value == null || value.isEmpty ? null : value;
  }

  Future<void> _signIn() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _failed = false;
    });

    try {
      var token = await GoogleSignInService.authenticator.authenticate(
        clientId: _optionalAttribute('clientId'),
        serverClientId: _optionalAttribute('serverClientId'),
      );
      if (token == null || token.isEmpty) {
        throw StateError('Google Sign-In returned no ID token');
      }
      await liveView.postForm({'id_token': token}, url: getAttribute('action'));
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget render(BuildContext context) {
    var label = getAttribute('label') ?? 'Continue with Google';
    var errorLabel =
        getAttribute('errorLabel') ??
        'Google sign-in failed. Please try again.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _loading ? null : _signIn,
          icon:
              _loading
                  ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text(
                    'G',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          label: Text(label),
        ),
        if (_failed) ...[
          const SizedBox(height: 8),
          Text(
            errorLabel,
            textAlign: TextAlign.center,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
