import 'package:flutter/material.dart';

BottomNavigationBarType? getBottomNavigationBarType(String? prop) {
  switch (prop) {
    case 'fixed':
      return BottomNavigationBarType.fixed;
    case 'shifting':
      return BottomNavigationBarType.shifting;
    default:
      return null;
  }
}

BottomNavigationBarLandscapeLayout? getBottomNavigationBarLandscapeLayout(
    String? prop) {
  switch (prop) {
    case 'centered':
      return BottomNavigationBarLandscapeLayout.centered;
    case 'linear':
      return BottomNavigationBarLandscapeLayout.linear;
    case 'spread':
      return BottomNavigationBarLandscapeLayout.spread;
    default:
      return null;
  }
}
