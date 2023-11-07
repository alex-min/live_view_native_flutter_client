import 'package:flutter/material.dart';

OptionsViewOpenDirection? getOptionsViewOpenDirection(String? prop) {
  switch (prop) {
    case 'down':
      return OptionsViewOpenDirection.down;
    case 'up':
      return OptionsViewOpenDirection.up;
    default:
      return null;
  }
}
