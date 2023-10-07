import 'package:flutter/material.dart';

TextDirection? getTextDirection(String? property) {
  switch (property) {
    case 'ltr':
      return TextDirection.ltr;
    case 'rtl':
      return TextDirection.rtl;
    default:
      return null;
  }
}
