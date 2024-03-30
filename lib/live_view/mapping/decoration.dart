import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/border.dart';
import 'package:liveview_flutter/live_view/mapping/border_radius.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';

Decoration? getDecoration(BuildContext context, String? css) {
  if (css == null) {
    return null;
  }

  Color? color;
  BorderRadius? borderRadius;
  Border? border;

  for (var (prop, value) in parseCss(css)) {
    switch (prop) {
      case 'background':
        color = getColor(context, value);
      case 'border-radius':
        borderRadius = getBorderRadius(value);
      case 'border':
        border = getBorder(context, value);
    }
  }

  return BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
  );
}
