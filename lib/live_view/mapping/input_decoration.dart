import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/border_radius.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/css.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';

InputDecoration getInputDecoration(
  BuildContext context,
  String? css, {
  Widget? icon,
  String? labelText,
  String? hintText,
}) {
  Color? fillColor;
  bool? filled;
  bool? isDense;
  ({InputBorder enabled, InputBorder focused})? borders;
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
        borders = _parseInputBorder(context, value, borderRadius);
      case 'borderRadius':
        borderRadius = getBorderRadius(value);
      case 'contentPadding':
        contentPadding = getEdgeInsets(value);
    }
  }

  // If a border radius was supplied without an explicit border, build an
  // outline border that uses the radius.
  if (borders == null && borderRadius != null) {
    var radius = borderRadius;
    borders = (
      enabled: OutlineInputBorder(borderRadius: radius),
      focused: OutlineInputBorder(borderRadius: radius),
    );
  }

  return InputDecoration(
    fillColor: fillColor,
    icon: icon,
    filled: filled,
    isDense: isDense,
    labelText: labelText,
    hintText: hintText,
    border: borders?.enabled,
    enabledBorder: borders?.enabled,
    focusedBorder: borders?.focused,
    contentPadding: contentPadding,
  );
}

({InputBorder enabled, InputBorder focused})? _parseInputBorder(
  BuildContext context,
  String value,
  BorderRadius? borderRadius,
) {
  var outlineColor = Theme.of(context).colorScheme.outline;
  var primaryColor = Theme.of(context).colorScheme.primary;

  switch (value.trim().toLowerCase()) {
    case 'none':
      return (enabled: InputBorder.none, focused: InputBorder.none);
    case 'underline':
      return (
        enabled: UnderlineInputBorder(
          borderSide: BorderSide(color: outlineColor),
        ),
        focused: UnderlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      );
    case 'outline':
      var radius = borderRadius ?? BorderRadius.circular(12);
      return (
        enabled: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: outlineColor),
        ),
        focused: OutlineInputBorder(
          borderRadius: radius,
          borderSide: BorderSide(color: primaryColor),
        ),
      );
    default:
      return null;
  }
}
