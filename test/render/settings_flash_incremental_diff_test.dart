import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

const _initialJson =
    r'''{"0":{"0":"","1":{"0":"pelos@pelos.pelos","1":"Log out","2":" phx-click=\"[[&quot;toggleTheme&quot;]]\"","s":["\n    <Row>\n      <TextButton live-patch=\"/users/settings\" style=\"foregroundColor: @theme.colorScheme.onSurfaceVariant; padding: 0 8\"><Text>","</Text></TextButton>\n      <TextButton phx-href=\"/users/log_out\" method=\"delete\" style=\"foregroundColor: @theme.colorScheme.onSurfaceVariant; padding: 0 8\"><Text>","</Text></TextButton>\n      <IconButton"," icon=\"dark_mode\" color=\"@theme.colorScheme.onSurfaceVariant\"></IconButton>\n    </Row>\n  "]},"s":["<AppBar backgroundColor=\"@theme.colorScheme.surface\" foregroundColor=\"@theme.colorScheme.onSurface\" elevation=\"0\" surfaceTintColor=\"#00FFFFFF\" scrolledUnderElevation=\"0\">\n  <title>\n    <Row>\n      <Image src=\"/images/logo.png\" width=\"28\" height=\"28\"></Image>\n      <SizedBox width=\"8.0\"></SizedBox>\n      <Text style=\"color: @theme.colorScheme.onSurface\">","</Text>\n    </Row>\n  </title>\n  ","\n</AppBar>"],"r":1},"1":{"0":"","1":"","s":["","\n",""]},"2":"P","3":"pelos@pelos.pelos","4":"20/07/2026","5":"","6":" initialValue=\"pelos@pelos.pelos3\"","7":" errors=\"[]\"","8":" enabled=\"true\"","9":" errors=\"[]\"","10":" enabled=\"true\"","11":{"s":["\n                  <ElevatedButton type=\"submit\">Change email</ElevatedButton>\n"]},"12":" initialValue=\"+33666641647\"","13":" errors=\"[]\"","14":" enabled=\"true\"","15":{"0":{"0":"Your phone number has not been verified yet","s":["\n                    <Text style=\"textTheme: bodyMedium; color: @theme.colorScheme.error\">\n","\n                    </Text>\n"]},"s":["\n                  <SizedBox height=\"8.0\"></SizedBox>\n","\n"]},"16":{"s":["\n                  <ElevatedButton type=\"submit\">Change phone number</ElevatedButton>\n"]},"17":{"0":"Once your phone number is verified, you will be asked to enter a code sent by SMS every time you log in for better security","1":"Verify my phone number by SMS","s":["\n                <SizedBox height=\"16.0\"></SizedBox>\n                <Container padding=\"16.0\" decoration=\"background: @theme.colorScheme.errorContainer; borderRadius: 12\">\n                  <Column crossAxisAlignment=\"start\">\n                    <Text style=\"textTheme: bodyMedium; color: @theme.colorScheme.onErrorContainer\">\n","\n                    </Text>\n                    <SizedBox height=\"12.0\"></SizedBox>\n                    <ElevatedButton navigate=\"/users/confirm-phone-number\">\n","\n                    </ElevatedButton>\n                  </Column>\n                </Container>\n"]},"18":"","19":" phx-trigger-action=\"false\"","20":" value=\"pelos@pelos.pelos\"","21":" errors=\"[]\"","22":" enabled=\"true\"","23":" errors=\"[]\"","24":" enabled=\"true\"","25":{"s":["\n                  <ElevatedButton type=\"submit\">Change password</ElevatedButton>\n"]},"s":["<flutter>\n  ","\n  <viewBody>\n    <SingleChildScrollView padding=\"24.0\">\n      <Column crossAxisAlignment=\"start\">\n        ","\n        <Row crossAxisAlignment=\"center\">\n          <Container width=\"56.0\" height=\"56.0\" alignment=\"center\" decoration=\"background: @theme.colorScheme.primary; borderRadius: 9999\">\n            <Text style=\"color: @theme.colorScheme.onPrimary; textTheme: titleLarge\">\n","\n            </Text>\n          </Container>\n          <SizedBox width=\"16.0\"></SizedBox>\n          <Column crossAxisAlignment=\"start\">\n            <Text style=\"textTheme: titleMedium; color: @theme.colorScheme.onSurface\">","</Text>\n            <Text style=\"textTheme: bodySmall; color: @theme.colorScheme.onSurfaceVariant\">\n              Member since ","\n            </Text>\n          </Column>\n        </Row>\n\n        <SizedBox height=\"24.0\"></SizedBox>\n","\n        <Card margin=\"20 0 0 0\">\n          <Container padding=\"24.0\">\n            <Column crossAxisAlignment=\"start\">\n              <Text style=\"textTheme: titleMedium; color: @theme.colorScheme.onSurface\">Change email</Text>\n              <SizedBox height=\"4.0\"></SizedBox>\n              <Text style=\"textTheme: bodySmall; color: @theme.colorScheme.onSurfaceVariant\">\n                Update the email address associated with your account.\n              </Text>\n              <SizedBox height=\"20.0\"></SizedBox>\n              <Form phx-change=\"validate_email\" phx-submit=\"update_email\">\n                <TextField name=\"user[email]\" label=\"Email\" keyboardType=\"emailAddress\" autocorrect=\"false\"",""," decoration=\"filled: true\"","></TextField>\n                <SizedBox height=\"16.0\"></SizedBox>\n                <TextField name=\"current_password\" label=\"Current password\" obscureText=\"true\" autocorrect=\"false\" enableSuggestions=\"false\""," decoration=\"filled: true\"","></TextField>\n                <SizedBox height=\"20.0\"></SizedBox>\n","\n              </Form>\n            </Column>\n          </Container>\n        </Card>\n\n        <Card margin=\"20 0 0 0\">\n          <Container padding=\"24.0\">\n            <Column crossAxisAlignment=\"start\">\n              <Text style=\"textTheme: titleMedium; color: @theme.colorScheme.onSurface\">Phone number</Text>\n              <SizedBox height=\"4.0\"></SizedBox>\n              <Text style=\"textTheme: bodySmall; color: @theme.colorScheme.onSurfaceVariant\">\n                Add or update the phone number associated with your account.\n              </Text>\n              <SizedBox height=\"20.0\"></SizedBox>\n              <Form phx-change=\"validate_phone_number\" phx-submit=\"update_phone_number\">\n                <TextField name=\"user[phone_number]\" label=\"Phone number\" keyboardType=\"phone\" autocorrect=\"false\"",""," decoration=\"filled: true\"","></TextField>\n","\n                <SizedBox height=\"20.0\"></SizedBox>\n","\n              </Form>\n","\n","\n            </Column>\n          </Container>\n        </Card>\n\n        <Card margin=\"20 0 0 0\">\n          <Container padding=\"24.0\">\n            <Column crossAxisAlignment=\"start\">\n              <Text style=\"textTheme: titleMedium; color: @theme.colorScheme.onSurface\">Change password</Text>\n              <SizedBox height=\"4.0\"></SizedBox>\n              <Text style=\"textTheme: bodySmall; color: @theme.colorScheme.onSurfaceVariant\">\n                Choose a strong password and confirm it below.\n              </Text>\n              <SizedBox height=\"20.0\"></SizedBox>\n              <Form phx-change=\"validate_password\" phx-submit=\"update_password\" action=\"/users/log_in?_action=password_updated\" method=\"post\"",">\n                <hidden name=\"user[email]\"","></hidden>\n                <TextField name=\"user[password]\" label=\"New password\" obscureText=\"true\" autocorrect=\"false\" enableSuggestions=\"false\""," decoration=\"filled: true\"","></TextField>\n                <SizedBox height=\"16.0\"></SizedBox>\n                <TextField name=\"user[password_confirmation]\" label=\"Confirm new password\" obscureText=\"true\" autocorrect=\"false\" enableSuggestions=\"false\""," decoration=\"filled: true\"","></TextField>\n                <SizedBox height=\"20.0\"></SizedBox>\n","\n              </Form>\n            </Column>\n          </Container>\n        </Card>\n        <SizedBox height=\"24.0\"></SizedBox>\n      </Column>\n    </SingleChildScrollView>\n  </viewBody>\n</flutter>"],"r":1,"t":null}''';
const _updateJson =
    r'''{"1":{"0":{"0":"Un lien pour confirmer votre courriel à été envoyé à la nouvelle adresse","s":["\n  <ScaffoldMessage kind=\"info\">\n    <Text>","</Text>\n  </ScaffoldMessage>\n"]},"1":""},"t":null}''';

main() async {
  testWidgets('settings flash incremental diff update renders correctly', (
    tester,
  ) async {
    var initial = jsonDecode(_initialJson) as Map<String, dynamic>;
    var update = jsonDecode(_updateJson) as Map<String, dynamic>;
    var view = LiveView();
    view.endpointScheme = 'http';
    view.host = 'localhost:9999';
    view.handleRenderedMessage(initial);

    await tester.runLiveView(view);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    view.handleDiffMessage(update);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.text(
        'Un lien pour confirmer votre courriel à été envoyé à la nouvelle adresse',
      ),
      findsOneWidget,
    );

    // The flash must be rendered as a ScaffoldMessage snackbar, not as raw XML text.
    expect(find.textContaining('<ScaffoldMessage'), findsNothing);
    expect(find.textContaining('{0: {0:'), findsNothing);

    // Let the scaffold message timer fire so the test can clean up.
    await tester.pump(const Duration(seconds: 5));
  });
}
