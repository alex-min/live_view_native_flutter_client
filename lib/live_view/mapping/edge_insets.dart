import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

EdgeInsets? getEdgeInsets(String? edges) {
  if (edges == null) {
    return null;
  }
  edges = edges.trim();
  if (!edges.matches(r'^[\d\s]+$')) {
    return null;
  }
  if (edges == '0') {
    return EdgeInsets.zero;
  }

  var values = edges
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'[^\d\s]'), '')
      .split(' ')
      .map((e) => double.tryParse(e))
      .toList();

  if (values.any((e) => e == null)) {
    return null;
  }

  var top = values[0] ?? 0.0;
  var right = values.elementAtOrNull(1) ?? top;
  var bottom = values.elementAtOrNull(2) ?? top;
  var left = values.elementAtOrNull(3) ?? right;

  return EdgeInsets.only(top: top, left: left, right: right, bottom: bottom);
}
