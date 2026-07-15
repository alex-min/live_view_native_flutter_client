import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
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
              <Container decoration="background: #232840; gradient: { radial #5353E58C #D94FC373 #232840 }">
                <SingleChildScrollView padding="24.0">
                  <Center>
                    <Container width="440.0">
                      <Column crossAxisAlignment="stretch">
                        <Column crossAxisAlignment="center">
                          <Icon name="smart_toy" color="#5353E5" size="48" />
                          <SizedBox height="16.0" />
                          <Container padding="6.0 12.0" decoration="background: #00BCD426; borderRadius: 20">
                            <Text style="textTheme: bodyMedium; color: #E0F7FA" textAlign="center">Sign in to your account</Text>
                          </Container>
                        </Column>
                        <SizedBox height="24.0" />
                        <Card color="#323A57" elevation="4">
                          <Container padding="24.0">
                            <Column crossAxisAlignment="stretch">
                              <Form method="POST">
                                <Text style="textTheme: bodyMedium; color: #E0E0E0">Email</Text>
                                <SizedBox height="4.0" />
                                <TextField
                                  name="user[email]"
                                  hintText="you@example.com"
                                  keyboardType="emailAddress"
                                  autocorrect="false"
                                  decoration="filled: true"
                                />
                                <SizedBox height="16.0" />
                                <Row>
                                  <Text style="textTheme: bodyMedium; color: #E0E0E0">Password</Text>
                                  <Expanded />
                                  <TextButton live-patch="/users/reset_password" style="padding: 0; minimumSize: 0; tapTargetSize: shrinkWrap">
                                    <Text style="textTheme: bodySmall; color: #5353E5">Forgot your password?</Text>
                                  </TextButton>
                                </Row>
                                <SizedBox height="4.0" />
                                <TextField
                                  name="user[password]"
                                  hintText="••••••••"
                                  obscureText="true"
                                  autocorrect="false"
                                  enableSuggestions="false"
                                  decoration="filled: true"
                                />
                                <SizedBox height="16.0" />
                                <Row>
                                  <Checkbox name="user[remember_me]" checked="true" value="true" />
                                  <Text style="color: #E0E0E0">Keep me logged in</Text>
                                </Row>
                                <SizedBox height="24.0" />
                                <Row>
                                  <Expanded>
                                    <ElevatedButton type="submit" style="backgroundColor: #5353E5; foregroundColor: #FFFFFF; shape: { radius 30 }; padding: { 14 24 }">Sign in</ElevatedButton>
                                  </Expanded>
                                </Row>
                              </Form>
                            </Column>
                          </Container>
                        </Card>
                        <SizedBox height="16.0" />
                        <TextButton live-patch="/users/register"><Text textAlign="center" style="color: #E0E0E0">Register your account</Text></TextButton>
                      </Column>
                    </Container>
                  </Center>
                </SingleChildScrollView>
              </Container>
            </viewBody>
            <BottomAppBar color="#232840B3" height="56.0">
              <Center>
                <Text style="textTheme: bodySmall; color: #A0A0A0" textAlign="center">© 2026 StartupKit. All rights reserved.</Text>
              </Center>
            </BottomAppBar>
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
    expect(find.byType(LiveBottomAppBar), findsOneWidget);
  });
}
