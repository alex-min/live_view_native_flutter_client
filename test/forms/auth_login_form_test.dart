import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_checkbox.dart';
import 'package:liveview_flutter/live_view/ui/components/live_elevated_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text_field.dart';

import '../test_helpers.dart';

void main() async {
  testWidgets('login form renders labels, padding and actions', (tester) async {
    var (view, _) = await connect(LiveView(), rendered: {
      's': [
        """
          <flutter>
            <viewBody>
              <SingleChildScrollView padding="24.0">
                <Center>
                  <Container width="360.0">
                    <Column crossAxisAlignment="stretch">
                      <Text style="textTheme: headlineSmall" textAlign="center">Sign in to your account</Text>
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
                                decoration="filled: true"
                              />
                              <SizedBox height="12.0" />
                              <Row>
                                <Checkbox name="user[remember_me]" checked="true" value="true" />
                                <Text>Keep me logged in</Text>
                              </Row>
                              <SizedBox height="20.0" />
                              <ElevatedButton type="submit">Sign in</ElevatedButton>
                            </Form>
                          </Column>
                        </Container>
                      </Card>
                      <SizedBox height="16.0" />
                      <TextButton live-patch="/users/register"><Text textAlign="center">Register your account</Text></TextButton>
                      <TextButton live-patch="/users/reset_password"><Text textAlign="center">Forgot your password?</Text></TextButton>
                    </Column>
                  </Container>
                </Center>
              </SingleChildScrollView>
            </viewBody>
          </flutter>
        """
      ]
    });

    await tester.runLiveView(view);
    await tester.pumpAndSettle();

    expect(find.text('Sign in to your account'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Keep me logged in'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('Register your account'), findsOneWidget);
    expect(find.text('Forgot your password?'), findsOneWidget);

    expect(find.byType(LiveTextField), findsNWidgets(2));
    expect(find.byType(LiveCheckbox), findsOneWidget);
    expect(find.byType(LiveElevatedButton), findsOneWidget);
    expect(find.byType(LiveTextButton), findsNWidgets(2));
  });
}
