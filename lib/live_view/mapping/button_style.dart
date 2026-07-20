import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';
import 'package:liveview_flutter/live_view/mapping/material_tap_target_size.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/mapping/text_style_map.dart';

ButtonStyle? getButtonStyle(BuildContext context, String? style) {
  if (style == null) {
    return null;
  }
  MaterialStateProperty<TextStyle?>? textStyle;
  MaterialStateProperty<Color?>? backgroundColor;
  MaterialStateProperty<Color?>? foregroundColor;
  MaterialStateProperty<Size?>? minimumSize;
  MaterialStateProperty<Size?>? maximumSize;
  MaterialStateProperty<EdgeInsetsGeometry?>? padding;
  MaterialStateProperty<OutlinedBorder?>? shape;
  MaterialTapTargetSize? tapTargetSize;

  for (var (styleKey, styleValue) in parseCss(style)) {
    switch (styleKey) {
      case 'textStyle':
        textStyle = getMaterialTextStyle(styleValue, context);
      case 'backgroundColor':
        backgroundColor = MaterialStateProperty.all(
          getColor(context, styleValue),
        );
      case 'foregroundColor':
        foregroundColor = MaterialStateProperty.all(
          getColor(context, styleValue),
        );
      case 'minimumSize':
        minimumSize = _parseSize(styleValue);
      case 'maximumSize':
        maximumSize = _parseSize(styleValue);
      case 'padding':
        padding = MaterialStateProperty.all(getEdgeInsets(styleValue));
      case 'shape':
        shape = _parseShape(styleValue);
      case 'tapTargetSize':
        tapTargetSize = getMaterialTapTargetSize(styleValue);
    }
  }
  return ButtonStyle(
    textStyle: textStyle,
    backgroundColor: backgroundColor,
    foregroundColor: foregroundColor,
    minimumSize: minimumSize,
    maximumSize: maximumSize,
    padding: padding,
    shape: shape,
    tapTargetSize: tapTargetSize,
  );
}

MaterialStateProperty<Size?>? _parseSize(String? value) {
  if (value == null) return null;
  var parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return null;

  var width = getDouble(parts[0]);
  if (width == null) return null;

  var height = parts.length > 1 ? getDouble(parts[1]) : width;
  if (height == null) return null;

  return MaterialStateProperty.all(Size(width, height));
}

MaterialStateProperty<OutlinedBorder?>? _parseShape(String? value) {
  if (value == null) return null;
  var parts = value.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return null;

  if (parts.first == 'circle') {
    return MaterialStateProperty.all(const CircleBorder());
  }

  if (parts.first == 'radius' && parts.length > 1) {
    var radius = double.tryParse(parts[1]);
    if (radius != null) {
      return MaterialStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius)),
      );
    }
  }

  return null;
}
