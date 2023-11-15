import 'package:flutter/material.dart';

ListTileTitleAlignment? getListTitleAligment(String? prop) {
  switch (prop) {
    case 'bottom':
      return ListTileTitleAlignment.bottom;
    case 'center':
      return ListTileTitleAlignment.center;
    case 'threeLine':
      return ListTileTitleAlignment.threeLine;
    case 'titleHeight':
      return ListTileTitleAlignment.titleHeight;
    case 'top':
      return ListTileTitleAlignment.top;
    default:
      return null;
  }
}
