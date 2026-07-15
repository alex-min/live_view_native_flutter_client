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
  Gradient? gradient;

  for (var (prop, value) in parseCss(css)) {
    switch (prop) {
      case 'background':
        color = getColor(context, value);
      case 'borderRadius':
        borderRadius = getBorderRadius(value);
      case 'border':
        border = getBorder(context, value);
      case 'gradient':
        gradient = _parseGradient(context, value);
    }
  }

  return BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
    gradient: gradient,
  );
}

/// Parses a simplified gradient declaration.
///
/// Syntax: `<linear|radial> [color stop]*`
/// Colors can be hex, named, or theme variables. Stops are optional floats
/// in the range 0..1 and, when omitted, are distributed evenly.
///
/// Examples:
///   gradient: linear #5353E5 #D94FC3
///   gradient: radial #5353E5 0.0 #D94FC3 1.0
Gradient? _parseGradient(BuildContext context, String value) {
  var parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length < 3) return null;

  var type = parts.first;
  var colors = <Color>[];
  var stops = <double>[];

  for (var i = 1; i < parts.length; i++) {
    var token = parts[i];
    var stop = double.tryParse(token);
    if (stop != null) {
      stops.add(stop);
    } else {
      var color = getColor(context, token);
      if (color != null) {
        colors.add(color);
      }
    }
  }

  if (colors.length < 2) return null;

  if (stops.length != colors.length) {
    stops = List.generate(colors.length, (i) => i / (colors.length - 1));
  }

  switch (type) {
    case 'linear':
      return LinearGradient(colors: colors, stops: stops);
    case 'radial':
      return RadialGradient(colors: colors, stops: stops);
    default:
      return null;
  }
}
