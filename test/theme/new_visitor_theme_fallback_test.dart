import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ThemeSettings buildSettings() {
    final settings =
        ThemeSettings()
          ..httpClient = MockClient((request) async {
            throw Exception('no theme server in tests');
          });
    return settings;
  }

  testWidgets('new visitors follow the OS appearance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final settings = buildSettings();

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.dark;
    await settings.loadPreferences();
    expect(settings.themeMode, ThemeMode.system);
    expect(settings.getDisplayedThemeMode(), ThemeMode.dark);

    tester.binding.platformDispatcher.platformBrightnessTestValue =
        Brightness.light;
    await settings.loadPreferences();
    expect(settings.getDisplayedThemeMode(), ThemeMode.light);
    addTearDown(
      tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
    );
  });

  test('a stored theme choice wins over the OS default', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final settings = buildSettings();

    await settings.loadPreferences();

    expect(settings.themeMode, ThemeMode.dark);
    expect(settings.getDisplayedThemeMode(), ThemeMode.dark);
  });

  test('the server default theme never overrides a local choice', () async {
    SharedPreferences.setMockInitialValues({'themeMode': 'dark'});
    final settings = buildSettings();
    await settings.loadPreferences();

    await settings.adoptServerTheme('cosmic', 'light');

    expect(settings.themeMode, ThemeMode.dark);
    // nothing new persisted over the local choice
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeMode'), 'dark');
  });

  test('an explicit server theme is adopted and persisted', () async {
    SharedPreferences.setMockInitialValues({});
    final settings = buildSettings();
    await settings.loadPreferences();

    await settings.adoptServerTheme('cosmic', 'dark');

    expect(settings.themeName, 'cosmic');
    expect(settings.themeMode, ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('themeName'), 'cosmic');
    expect(prefs.getString('themeMode'), 'dark');
  });
}
