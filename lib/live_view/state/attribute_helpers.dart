import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/mapping/navigation_rail_label_type.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';

mixin AttributeHelpers {
  String? getAttribute(String name);

  // attributes
  double? doubleAttribute(String attribute) =>
      getDouble(getAttribute(attribute));
  int? intAttribute(String attribute) => getInt(getAttribute(attribute));
  Color? colorAttribute(BuildContext context, String attribute) =>
      getColor(context, getAttribute(attribute));
  bool? booleanAttribute(String attribute) =>
      getBoolean(getAttribute(attribute));
  Decoration? decorationAttribute(BuildContext context, String attribute) =>
      getDecoration(context, getAttribute(attribute));
  EdgeInsetsGeometry? edgeInsetsAttribute(String attribute) =>
      getMarginOrPadding(getAttribute(attribute));
  Icon getIconAttribute(String attribute) =>
      Icon(getIcon(getAttribute(attribute)));
  NavigationRailLabelType? getNavigationRailLabelTypeAttribute(attribute) =>
      getNavigationRailLabelType(getAttribute(attribute));
}
