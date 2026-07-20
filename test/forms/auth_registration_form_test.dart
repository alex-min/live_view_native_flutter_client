import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('registration form renders labels, hint and actions', (
    tester,
  ) async {
    var (view, _) = await connect(
      LiveView(),
      rendered: {
        's': [
          """
          <flutter>
            <viewBody>
              <SingleChildScrollView padding="24.0">
                <Center>
                  <Container width="360.0">
                    <Column crossAxisAlignment="stretch">
                      <Text style="textTheme: headlineSmall" textAlign="center">Register your account</Text>
                      <SizedBox height="24.0" />
                      <Card>
                        <Container padding="24.0">
                          <Column crossAxisAlignment="stretch">
                            <Form method="POST">
                              <TextField
                                name="user[email]"
                                label="Email"
                                keyboardType="emailAddress"
                                autocorrect="false"
                                decoration="filled: true"
                              />
                              <SizedBox height="16.0" />
                              <TextField
                                name="user[password]"
                                label="Password"
                                obscureText="true"
                                autocorrect="false"
                                enableSuggestions="false"
                                hintText="Password must be at least 8 characters"
                                decoration="filled: true"
                              />
                              <SizedBox height="16.0" />
                              <TextField
                                name="user[password_confirmation]"
                                label="Confirm password"
                                obscureText="true"
                                autocorrect="false"
                                enableSuggestions="false"
                                decoration="filled: true"
                              />
                              <SizedBox height="20.0" />
                              <ElevatedButton type="submit">Create an account</ElevatedButton>
                            </Form>
                          </Column>
                        </Container>
                      </Card>
                      <SizedBox height="16.0" />
                      <TextButton live-patch="/users/log_in"><Text textAlign="center">Sign-in to your account</Text></TextButton>
                    </Column>
                  </Container>
                </Center>
              </SingleChildScrollView>
            </viewBody>
          </flutter>
        """,
        ],
      },
    );

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('Register your account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    expect(find.text('Create an account'), findsOneWidget);
    expect(find.text('Sign-in to your account'), findsOneWidget);

    expect(find.byType(LiveTextField), findsNWidgets(3));
    expect(find.byType(LiveElevatedButton), findsOneWidget);
    expect(find.byType(LiveTextButton), findsOneWidget);
  });
}
