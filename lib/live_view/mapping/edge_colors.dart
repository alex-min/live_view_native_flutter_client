import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';

EdgeColors getEdgeColors(BuildContext context, String? borderColors) {
  if (borderColors == null) {
    return EdgeColors.zero;
  }

  var values = borderColors.split(' ');

  var top = values[0];
  var right = values.elementAtOrNull(1) ?? top;
  var bottom = values.elementAtOrNull(2) ?? top;
  var left = values.elementAtOrNull(3) ?? right;

  return EdgeColors(
    top: getColor(context, top) ?? const Color(0xFF000000),
    right: getColor(context, right) ?? const Color(0xFF000000),
    bottom: getColor(context, bottom) ?? const Color(0xFF000000),
    left: getColor(context, left) ?? const Color(0xFF000000),
  );
}

class EdgeColors {
  final Color top;
  final Color right;
  final Color bottom;
  final Color left;

  const EdgeColors({
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
  });

  const EdgeColors.all(Color value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const EdgeColors.only({
    this.left = Colors.black,
    this.top = Colors.black,
    this.right = Colors.black,
    this.bottom = Colors.black,
  });

  const EdgeColors.symmetric({
    Color vertical = Colors.black,
    Color horizontal = Colors.black,
  })  : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;

  static const EdgeColors zero = EdgeColors.all(Colors.black);

  @override
  int get hashCode => Object.hash(top, right, bottom, left);

  @override
  bool operator ==(Object other) =>
      other is EdgeColors &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.left == left;

  @override
  String toString() {
    return 'EdgeColors(top: $top, right: $right, bottom: $bottom, left: $left)';
  }
}
