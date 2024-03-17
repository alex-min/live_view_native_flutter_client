import 'package:flutter/rendering.dart';

Axis? getAxis(String? prop) {
  switch (prop) {
    case 'vertical':
      return Axis.vertical;
    case 'horizontal':
      return Axis.horizontal;
    default:
      return null;
  }
}
