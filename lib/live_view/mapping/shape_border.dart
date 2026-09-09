import 'package:flutter/rendering.dart';

ShapeBorder? getShapeBorder(String? prop) {
  if (prop?.startsWith('RoundedRectangleBorder:') == true) {
    final radius = double.tryParse(prop!.split(':').last.trim());
    if (radius != null) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
      );
    }
  }

  switch (prop) {
    case 'CircleBorder':
      return const CircleBorder();
    case 'BeveledRectangleBorder':
      return const BeveledRectangleBorder();
    default:
      return null;
  }
}
