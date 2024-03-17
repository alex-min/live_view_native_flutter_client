import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';

ButtonStyle? getButtonStyle(BuildContext context, String? style) {
  if (style == null) {
    return null;
  }
  MaterialStateProperty<TextStyle?>? textStyle;

  for (var (styleKey, styleValue) in parseCss(style)) {
    switch (styleKey) {
      case 'textStyle':
        textStyle = getMaterialTextStyle(styleValue, context);
        break;
    }
  }
  return ButtonStyle(textStyle: textStyle);
}
