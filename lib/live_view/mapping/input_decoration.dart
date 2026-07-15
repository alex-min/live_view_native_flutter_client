import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/border_radius.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';

InputDecoration getInputDecoration(BuildContext context, String? css,
    {Widget? icon, String? labelText, String? hintText}) {
  Color? fillColor;
  bool? filled;
  bool? isDense;
  InputBorder? border;
  BorderRadius? borderRadius;
  EdgeInsets? contentPadding;

  for (var (prop, value) in parseCss(css ?? '')) {
    switch (prop) {
      case 'fillColor':
        fillColor = getColor(context, value);
      case 'filled':
        filled = getBoolean(value);
      case 'isDense':
        isDense = getBoolean(value);
      case 'border':
        border = _parseInputBorder(context, value, borderRadius);
      case 'borderRadius':
        borderRadius = getBorderRadius(value);
      case 'contentPadding':
        contentPadding = getEdgeInsets(value);
    }
  }

  // If a border radius was supplied without an explicit border, build an
  // outline border that uses the radius.
  if (border == null && borderRadius != null) {
    border = OutlineInputBorder(borderRadius: borderRadius);
  }

  return InputDecoration(
    fillColor: fillColor,
    icon: icon,
    filled: filled,
    isDense: isDense,
    labelText: labelText,
    hintText: hintText,
    border: border,
    enabledBorder: border,
    focusedBorder: border,
    contentPadding: contentPadding,
  );
}

InputBorder? _parseInputBorder(
    BuildContext context, String value, BorderRadius? borderRadius) {
  var outlineColor = Theme.of(context).colorScheme.outline;

  switch (value.trim().toLowerCase()) {
    case 'none':
      return InputBorder.none;
    case 'underline':
      return UnderlineInputBorder(
        borderSide: BorderSide(color: outlineColor),
      );
    case 'outline':
      return OutlineInputBorder(
        borderRadius: borderRadius ?? BorderRadius.circular(12),
        borderSide: BorderSide(color: outlineColor),
      );
    default:
      return null;
  }
}
