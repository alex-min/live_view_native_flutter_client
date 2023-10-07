import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';

InputDecoration getInputDecoration(BuildContext context, String? css,
    {Widget? icon}) {
  Color? fillColor;
  bool? filled;
  bool? isDense;
  for (var (prop, value) in parseCss(css ?? '')) {
    switch (prop) {
      case 'fillColor':
        fillColor = getColor(context, value);
      case 'filled':
        filled = getBoolean(value);
      case 'isDense':
        isDense = getBoolean(value);
    }
  }
  return InputDecoration(
      fillColor: fillColor, icon: icon, filled: filled, isDense: isDense);
}
