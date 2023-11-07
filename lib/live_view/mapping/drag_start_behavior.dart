import 'package:flutter/gestures.dart';

DragStartBehavior? getDragStartBehavior(String? prop) {
  switch (prop) {
    case 'down':
      return DragStartBehavior.down;
    case 'start':
      return DragStartBehavior.start;
    default:
      return null;
  }
}
