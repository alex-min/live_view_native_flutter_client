import 'package:flutter/material.dart';

TextBaseline? getTextBaseline(String? prop) {
  switch (prop) {
    case 'alphabetic':
      return TextBaseline.alphabetic;
    case 'ideographic':
      return TextBaseline.ideographic;
    default:
      return null;
  }
}
