import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';
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
              <Stack>
                <CosmicBackground />
                <SingleChildScrollView padding="24.0">
                  <Center>
                    <Container width="460.0">
                      <Column crossAxisAlignment="stretch">
                        <Column crossAxisAlignment="center">
                          <Container width="64.0" height="64.0" decoration="background: #736E63E5; borderRadius: 9999; border: { 1 #404868 }; boxShadow: { 0 12 32 -8 #8C5353E5 }">
                            <Center>
                              <Icon name="smart_toy" color="#5353E5" size="32" />
                            </Center>
                          </Container>
                          <SizedBox height="12.0" />
                          <Text style="textTheme: bodyMedium; color: #A8B0CC" textAlign="center">Sign in to your account</Text>
                        </Column>
                        <SizedBox height="24.0" />
                        <Container padding="32.0" decoration="background: #EB323A57; borderRadius: 20; border: { 1 #404868 }; boxShadow: { 0 24 60 -24 #8C000000 }">
                          <Column crossAxisAlignment="stretch">
                            <Form method="POST">
                              <Text style="textTheme: bodyMedium; color: #A8B0CC">Email</Text>
                              <SizedBox height="6.0" />
                              <TextField
                                name="user[email]"
                                hintText="you@example.com"
                                keyboardType="emailAddress"
                                autocorrect="false"
                                decoration="filled: true; fillColor: #3A4363; border: outline; borderRadius: 12; contentPadding: { 12 14 }"
                              />
                              <SizedBox height="16.0" />
                              <Row mainAxisAlignment="spaceBetween">
                                <Text style="textTheme: bodyMedium; color: #A8B0CC">Password</Text>
                                <TextButton live-patch="/users/reset_password" style="padding: 0; minimumSize: 0; tapTargetSize: shrinkWrap">
                                  <Text style="textTheme: bodySmall; color: #A8B0CC">Forgot your password?</Text>
                                </TextButton>
                              </Row>
                              <SizedBox height="6.0" />
                              <TextField
                                name="user[password]"
                                hintText="••••••••"
                                obscureText="true"
                                autocorrect="false"
                                enableSuggestions="false"
                                decoration="filled: true; fillColor: #3A4363; border: outline; borderRadius: 12; contentPadding: { 12 14 }"
                              />
                              <SizedBox height="16.0" />
                              <Row>
                                <Checkbox name="user[remember_me]" checked="true" value="true" />
                                <Text style="color: #A8B0CC">Keep me logged in</Text>
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
                        <SizedBox height="16.0" />
                        <TextButton live-patch="/users/register" style="padding: 0; minimumSize: 0; tapTargetSize: shrinkWrap"><Text textAlign="center" style="color: #A8B0CC">Register your account</Text></TextButton>
                      </Column>
                    </Container>
                  </Center>
                </SingleChildScrollView>
              </Stack>
            </viewBody>
            <BottomAppBar color="#B3323A57" height="56.0" elevation="0">
              <Center>
                <Text style="textTheme: bodySmall; color: #6B7594" textAlign="center">© 2026 StartupKit. All rights reserved.</Text>
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
    expect(find.byType(LiveCosmicBackground), findsOneWidget);
  });
}
