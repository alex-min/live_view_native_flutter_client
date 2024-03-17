import 'package:flutter/material.dart';

MaterialState? getMaterialState(String? value) {
  switch (value) {
    case 'disabled':
      return MaterialState.disabled;
    case 'hovered':
      return MaterialState.hovered;
    case 'focused':
      return MaterialState.focused;
    case 'pressed':
      return MaterialState.pressed;
    case 'dragged':
      return MaterialState.dragged;
    case 'selected':
      return MaterialState.selected;
    case 'scrolledUnder':
      return MaterialState.scrolledUnder;
    case 'error':
      return MaterialState.error;
    default:
      return null;
  }
}
