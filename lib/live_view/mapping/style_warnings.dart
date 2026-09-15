import 'package:flutter/foundation.dart';

/// Reports invalid server-driven style declarations in debug builds only.
void warnInvalidStyle(String parser, String message) {
  assert(() {
    debugPrint('LiveView $parser style warning: $message');
    return true;
  }());
}
