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
