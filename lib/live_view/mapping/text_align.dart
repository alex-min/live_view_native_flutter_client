import 'package:flutter/material.dart';

TextAlign? getTextAlign(String? prop) {
  switch (prop) {
    case 'center':
      return TextAlign.center;
    case 'end':
      return TextAlign.end;
    case 'start':
      return TextAlign.start;
    case 'right':
      return TextAlign.right;
    case 'justify':
      return TextAlign.justify;
    default:
      return null;
  }
}
