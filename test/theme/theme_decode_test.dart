import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:json_theme/json_theme.dart';

main() {
  test('decodes the startup_kit light theme without errors', () {
    var file = File('../startup_kit/priv/static/flutter/themes/default/light.json');
    var json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

    var theme = ThemeDecoder.instance.decodeThemeData(json);

    expect(theme, isNotNull);
    expect(theme!.colorScheme.primary, const Color(0xff5353e5));
  });
}
