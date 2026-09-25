import 'package:flutter_test/flutter_test.dart';

import 'appearance_theme_scenario.dart' as appearance_theme;
import 'cache_manifest_navigation_scenario.dart' as cache_manifest;
import 'email_change_scenario.dart' as email_change;
import 'settings_default_currency_scenario.dart' as default_currency;
import 'support_chat_scenario.dart' as support_chat;
import 'theme_settings_scenario.dart' as theme_settings;

void main() {
  group('Appearance', appearance_theme.main);
  group('Theme settings', theme_settings.main);
  group('Default currency', default_currency.main);
  group('Email change', email_change.main);
  group('Support chat', support_chat.main);
  group('Cache navigation', cache_manifest.main);
}
