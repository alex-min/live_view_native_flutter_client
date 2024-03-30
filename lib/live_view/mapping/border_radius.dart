import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';

BorderRadius? getBorderRadius(String? borderRadio) {
  var edges = getEdgeInsets(borderRadio);

  if (edges == null) {
    return null;
  }

  return BorderRadius.only(
    topLeft: Radius.circular(edges.top),
    topRight: Radius.circular(edges.right),
    bottomRight: Radius.circular(edges.bottom),
    bottomLeft: Radius.circular(edges.left),
  );
}
