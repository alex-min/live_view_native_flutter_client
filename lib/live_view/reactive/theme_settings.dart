import 'package:flutter/material.dart';
import 'package:json_theme/json_theme.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ThemeSettings extends ChangeNotifier {
  http.Client httpClient = http.Client();
  late String host;

  String _themeName = 'default';
  ThemeMode _themeMode = ThemeMode.system;
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;

  ThemeMode get themeMode => _themeMode;

  ThemeData? get lightTheme => _lightTheme;
  ThemeData? get darkTheme => _darkTheme;

  Future<void> setTheme(String name, String mode) async {
    _themeName = name;
    _themeMode = ThemeModeStringify.parse(mode);
    return fetchCurrentTheme();
  }

  Future<void> save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('themeName', _themeName);
    await prefs.setString('themeMode', _themeMode.modeAsString());
  }

  Future<void> loadPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _themeName = prefs.getString('themeName') ?? 'default';
    _themeMode =
        ThemeModeStringify.parse(prefs.getString('themeMode') ?? 'system');
    notifyListeners();
  }

  Future<void> loadCurrentTheme() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var theme = prefs.getString(_currentThemeKey);
    if (theme == null) {
      return;
    }
    var content = tryJsonDecode(theme);
    if (content == null) {
      return;
    }
    try {
      switch (getDisplayedThemeMode()) {
        case ThemeMode.light:
          _lightTheme = ThemeDecoder.decodeThemeData(content);
        case ThemeMode.dark:
          _darkTheme = ThemeDecoder.decodeThemeData(content);
        case ThemeMode.system:
          throw Exception('unreachable');
      }
    } catch (e, stack) {
      print(stack);
    }
    notifyListeners();
  }

  Future<void> saveJsonCurrentTheme(String? json) async {
    if (json == null || tryJsonDecode(json) == null) {
      return;
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_currentThemeKey, json);
  }

  String get _currentThemeKey =>
      'themeData:$_themeName/${getDisplayedThemeMode().modeAsString()}';

  ThemeMode getDisplayedThemeMode() {
    if (_themeMode == ThemeMode.light || _themeMode == ThemeMode.dark) {
      return _themeMode;
    }
    var systemBrightness =
        WidgetsBinding.instance.platformDispatcher.platformBrightness;
    if (systemBrightness == Brightness.light) {
      return ThemeMode.light;
    } else {
      return ThemeMode.dark;
    }
  }

  Future<void> fetchCurrentTheme() async {
    await loadCurrentTheme();
    await httpClient
        .get(Uri.parse(
            '$host/flutter/themes/$_themeName/${getDisplayedThemeMode().modeAsString()}.json'))
        .then((response) {
      if (response.statusCode == 200) {
        saveJsonCurrentTheme(response.body);
        loadCurrentTheme();
      }
    });
  }
}
