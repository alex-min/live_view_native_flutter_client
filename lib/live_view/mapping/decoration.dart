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
  List<BoxShadow>? boxShadow;

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
      case 'boxShadow':
        var shadow = _parseBoxShadow(context, value);
        if (shadow != null) {
          boxShadow = [shadow];
        }
    }
  }

  return BoxDecoration(
    color: color,
    borderRadius: borderRadius,
    border: border,
    gradient: gradient,
    boxShadow: boxShadow,
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

/// Parses a simplified box-shadow declaration.
///
/// Syntax: `<offsetX> <offsetY> <blurRadius> <spreadRadius> <color>`
/// All values except color are numbers (logical pixels). Colors can be hex,
/// named, or theme variables. Spread radius is optional.
///
/// Examples:
///   boxShadow: { 0 24 60 -24 #8C000000 }
///   boxShadow: { 0 4 12 0 #805353E5 }
BoxShadow? _parseBoxShadow(BuildContext context, String value) {
  var parts = value.trim().split(RegExp(r'\s+'));
  if (parts.length < 4) return null;

  var offsetX = double.tryParse(parts[0]);
  var offsetY = double.tryParse(parts[1]);
  var blurRadius = double.tryParse(parts[2]);

  if (offsetX == null || offsetY == null || blurRadius == null) {
    return null;
  }

  // The 4th token is either the spread radius or the color.
  double spreadRadius = 0;
  String? colorToken;
  if (parts.length == 4) {
    colorToken = parts[3];
  } else {
    var maybeSpread = double.tryParse(parts[3]);
    if (maybeSpread != null) {
      spreadRadius = maybeSpread;
      colorToken = parts.sublist(4).join(' ');
    } else {
      colorToken = parts.sublist(3).join(' ');
    }
  }

  var color = getColor(context, colorToken);
  if (color == null) return null;

  return BoxShadow(
    offset: Offset(offsetX, offsetY),
    blurRadius: blurRadius,
    spreadRadius: spreadRadius,
    color: color,
  );
}
