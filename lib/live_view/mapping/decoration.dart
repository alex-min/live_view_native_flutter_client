import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';

Decoration? getDecoration(BuildContext context, String? css) {
  if (css == null) {
    return null;
  }

  Color? color;

  for (var (prop, value) in parseCss(css)) {
    switch (prop) {
      case 'background':
        color = getColor(context, value);
    }
  }
  return BoxDecoration(color: color);
}
