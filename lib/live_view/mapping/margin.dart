import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

EdgeInsetsGeometry? getMarginOrPadding(String? margin) {
  if (margin == null) {
    return null;
  }
  margin = margin.trim();
  var valid = margin.matches(r'^[\d ]+$');
  if (!valid) {
    return null;
  }

  margin.replaceAll(RegExp(r' +'), ' ');
  var margins = margin.split(' ');

  switch (margins.length) {
    case 1:
      return EdgeInsets.all(double.parse(margins[0]));
    case 2:
      return EdgeInsets.symmetric(
        vertical: double.parse(margins[0]),
        horizontal: double.parse(margins[1]),
      );
    case 4:
      return EdgeInsets.only(
        top: double.parse(margins[0]),
        left: double.parse(margins[1]),
        right: double.parse(margins[2]),
        bottom: double.parse(margins[3]),
      );
  }
  return null;
}
