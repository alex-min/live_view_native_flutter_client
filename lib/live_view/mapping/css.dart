import 'package:liveview_flutter/live_view/mapping/style_warnings.dart';

extension StringX on String {
  bool isNumber() {
    final value = codeUnitAt(0);
    return value >= 48 && value <= 57;
  }
}

List<(String, String)> parseCss(String style) {
  final declarations = <(String, String)>[];
  var cursor = 0;

  while (cursor < style.length) {
    while (cursor < style.length &&
        (style[cursor].trim().isEmpty || style[cursor] == ';')) {
      cursor++;
    }
    if (cursor >= style.length) break;

    final propertyStart = cursor;
    while (cursor < style.length && style[cursor] != ':') {
      cursor++;
    }
    if (cursor >= style.length) {
      warnInvalidStyle(
        'CSS',
        'missing value for property "${style.substring(propertyStart).trim()}" in "$style"',
      );
      break;
    }

    final property = style
        .substring(propertyStart, cursor)
        .trim()
        .replaceFirst(RegExp(r'^[^A-Za-z0-9@#]+'), '');
    cursor++;
    while (cursor < style.length && style[cursor].trim().isEmpty) {
      cursor++;
    }

    String value;
    if (cursor < style.length && style[cursor] == '{') {
      cursor++;
      final valueStart = cursor;
      var depth = 1;
      while (cursor < style.length && depth > 0) {
        if (style[cursor] == '{') depth++;
        if (style[cursor] == '}') depth--;
        cursor++;
      }
      value =
          style.substring(valueStart, depth == 0 ? cursor - 1 : cursor).trim();
    } else {
      final valueStart = cursor;
      while (cursor < style.length &&
          style[cursor] != ';' &&
          style[cursor] != '\n') {
        cursor++;
      }
      value = style.substring(valueStart, cursor).trim();
    }

    if (property.isEmpty || value.isEmpty) {
      warnInvalidStyle(
        'CSS',
        'invalid declaration "$property: $value" in "$style"',
      );
    } else {
      declarations.add((property, value));
    }
  }

  return declarations;
}
