import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/edge_colors.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';

Border? getBorder(BuildContext context, String? border) {
  var exp = RegExp(
    r'^((?:\d+\s?)+)((?:(?:[@a-z\.]+\s?)|(?:#[a-f0-9]+\s?))*)$',
    caseSensitive: false,
  );
  if (border == null || !exp.hasMatch(border)) {
    return null;
  }

  var match = exp.firstMatch(border)!;
  var widths = match[0];
  var colors = match[1];

  var edgesWidths = getEdgeInsets(widths);

  if (edgesWidths == null) {
    return null;
  }

  var edgesColors = getEdgeColors(context, colors);

  return Border(
    top: BorderSide(width: edgesWidths.top, color: edgesColors.top),
    right: BorderSide(width: edgesWidths.right, color: edgesColors.right),
    bottom: BorderSide(width: edgesWidths.bottom, color: edgesColors.bottom),
    left: BorderSide(width: edgesWidths.left, color: edgesColors.left),
  );
}
