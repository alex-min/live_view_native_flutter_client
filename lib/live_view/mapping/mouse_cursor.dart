import 'package:flutter/rendering.dart';

MouseCursor? getMouseCursor(String? attribute) {
  switch (attribute) {
    case 'defer':
      return MouseCursor.defer;
    case 'uncontrolled':
      return MouseCursor.uncontrolled;
    default:
      return null;
  }
}
