import 'package:flutter/widgets.dart';

ScrollViewKeyboardDismissBehavior? getScrollViewKeyboardDismissBehavior(
    String? prop) {
  switch (prop) {
    case 'manual':
      return ScrollViewKeyboardDismissBehavior.manual;
    case 'onDrag':
      return ScrollViewKeyboardDismissBehavior.onDrag;
    default:
      return null;
  }
}
