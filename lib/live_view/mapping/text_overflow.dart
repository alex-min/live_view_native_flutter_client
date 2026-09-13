import 'package:flutter/material.dart';

TextOverflow? getTextOverflow(String? prop) {
  switch (prop) {
    case 'clip':
      return TextOverflow.clip;
    case 'ellipsis':
      return TextOverflow.ellipsis;
    case 'fade':
      return TextOverflow.fade;
    case 'visible':
      return TextOverflow.visible;
    default:
      if (prop != null) {
        debugPrint("Unknown text overflow property $prop");
      }
      return null;
  }
}
