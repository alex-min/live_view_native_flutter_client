import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

import '../test_helpers.dart';

main() async {
  testWidgets('settings email form shows email validation error', (
    tester,
  ) async {
    var (view, _) = await connect(
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
                      errors='[{"message": "must have the @ sign and no spaces", "options": {}}]'
                      decoration="filled: true"
                    />
                    <SizedBox height="20.0" />
                    <ElevatedButton type="submit">Change email</ElevatedButton>
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

    expect(find.text('must have the @ sign and no spaces'), findsOneWidget);
  });
}
