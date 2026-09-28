import 'package:flutter_test/flutter_test.dart';

import 'google_sign_in_scenario.dart' as google_sign_in;
import 'onboarding_flow_scenario.dart' as onboarding;
import 'registration_after_switching_auth_pages_scenario.dart' as registration;

void main() {
  group('Onboarding', onboarding.main);
  group('Registration navigation', registration.main);
  group('Google sign-in', google_sign_in.main);
}
