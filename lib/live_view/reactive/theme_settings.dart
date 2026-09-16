import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:json_theme/json_theme.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettings extends ChangeNotifier {
  http.Client httpClient = http.Client();
  late String host;

  String _themeName = 'cosmic';
  ThemeMode _themeMode = ThemeMode.light;
  ThemeData? _lightTheme;
  ThemeData? _darkTheme;
  final Map<String, ThemeData> _decodedThemes = {};
  final Map<String, String> _themeJson = {};
  int _loadGeneration = 0;

  String get themeName => _themeName;
  ThemeMode get themeMode => _themeMode;

  ThemeData? get lightTheme => _lightTheme;
  ThemeData? get darkTheme => _darkTheme;

  Future<void> setTheme(String name, String mode) async {
    if (_themeName == name && _themeMode.modeAsString() == mode) {
      return;
    }
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
    _themeName = prefs.getString('themeName') ?? 'cosmic';
    _themeMode = ThemeModeStringify.parse(
      prefs.getString('themeMode') ?? 'light',
    );
    notifyListeners();
  }

  Future<void> loadCurrentTheme() async {
    final selection = _currentSelection;
    final generation = ++_loadGeneration;
    await _loadStoredTheme(selection, generation);
  }

  Future<String?> _loadStoredTheme(
    ({String name, ThemeMode mode, String key}) selection,
    int generation,
  ) async {
    final decoded = _decodedThemes[selection.key];
    if (decoded != null) {
      _applyTheme(selection, decoded, generation);
      return _themeJson[selection.key];
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var theme = prefs.getString(selection.key);
    if (theme == null) {
      return null;
    }
    var content = tryJsonDecode(theme);
    if (content == null) {
      return null;
    }
    // material 3 is the future of material in flutter
    // we set it as true to not break the theme in future updates
    // because this will be set as true by default later in a future update
    content['useMaterial3'] ??= true;
    try {
      final decoded = ThemeDecoder.instance.decodeThemeData(content);
      if (decoded == null) return theme;
      _decodedThemes[selection.key] = decoded;
      _themeJson[selection.key] = theme;
      _applyTheme(selection, decoded, generation);
    } catch (e, stack) {
      log(e.toString(), stackTrace: stack);
    }
    return theme;
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

  ({String name, ThemeMode mode, String key}) get _currentSelection {
    final mode = getDisplayedThemeMode();
    return (
      name: _themeName,
      mode: mode,
      key: 'themeData:$_themeName/${mode.modeAsString()}',
    );
  }

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
    final selection = _currentSelection;
    final generation = ++_loadGeneration;
    final storedJson = await _loadStoredTheme(selection, generation);
    if (!_isCurrent(selection, generation)) return;

    try {
      final response = await httpClient.get(
        Uri.parse(
          '$host/flutter/themes/${selection.name}/${selection.mode.modeAsString()}.json',
        ),
      );
      if (response.statusCode != 200 ||
          response.body == storedJson ||
          !_isCurrent(selection, generation)) {
        return;
      }

      final content = tryJsonDecode(response.body);
      if (content == null) return;
      content['useMaterial3'] ??= true;
      final decoded = ThemeDecoder.instance.decodeThemeData(content);
      if (decoded == null) return;
      if (!_isCurrent(selection, generation)) return;

      _decodedThemes[selection.key] = decoded;
      _themeJson[selection.key] = response.body;
      _applyTheme(selection, decoded, generation);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(selection.key, response.body);
    } catch (e) {
      // We don't care if fetching the theme fails
    }
  }

  bool _isCurrent(
    ({String name, ThemeMode mode, String key}) selection,
    int generation,
  ) =>
      generation == _loadGeneration &&
      selection.name == _themeName &&
      selection.mode == getDisplayedThemeMode();

  void _applyTheme(
    ({String name, ThemeMode mode, String key}) selection,
    ThemeData theme,
    int generation,
  ) {
    if (!_isCurrent(selection, generation)) return;
    switch (selection.mode) {
      case ThemeMode.light:
        _lightTheme = theme;
      case ThemeMode.dark:
        _darkTheme = theme;
      case ThemeMode.system:
        throw StateError('A displayed theme cannot use system mode');
    }
    notifyListeners();
  }
}
