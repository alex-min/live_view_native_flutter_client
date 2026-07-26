import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('settings email change form submits without current password', (
    tester,
  ) async {
    var (view, server) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <AppBar>
              <title><Text>Settings</Text></title>
            </AppBar>
            <viewBody>
              <SingleChildScrollView padding="24.0">
                <Column crossAxisAlignment="start">
                  <Form phx-change="validate_email" phx-submit="update_email">
                    <TextField
                      name="user[email]"
                      label="Email"
                      keyboardType="emailAddress"
                      autocorrect="false"
                      initialValue="user@example.com"
                      decoration="filled: true"
                    />
                    <SizedBox height="20.0" />
                    <ElevatedButton type="submit" name="submit">Change email</ElevatedButton>
                  </Form>
                </Column>
              </SingleChildScrollView>
            </viewBody>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'new@example.com');
    await tester.tap(find.byType(LiveElevatedButton));
    await tester.pumpAndSettle();

    expect(
      server.lastChannelAction,
      liveEvents.phxFormValidate(
        'update_email',
        'user%5Bemail%5D=new%40example.com&_target=submit',
      ),
    );
  });
}
