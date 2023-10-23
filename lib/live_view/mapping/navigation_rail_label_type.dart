import 'package:flutter/material.dart';

NavigationRailLabelType? getNavigationRailLabelType(String? attribute) {
  switch (attribute) {
    case 'all':
      return NavigationRailLabelType.all;
    case 'selected':
      return NavigationRailLabelType.selected;
    case 'none':
      return NavigationRailLabelType.none;
    default:
      return null;
  }
}
