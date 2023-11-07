import 'package:flutter/rendering.dart';

ShapeBorder? getShapeBorder(String? prop) {
  // TODO: handle all the kinds of custom shape
  switch (prop) {
    case 'CircleBorder':
      return const CircleBorder();
    case 'BeveledRectangleBorder':
      return const BeveledRectangleBorder();
    default:
      return null;
  }
}
