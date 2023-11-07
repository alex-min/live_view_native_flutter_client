import 'package:flutter/material.dart';

MaterialTapTargetSize? getMaterialTapTargetSize(String? prop) {
  switch (prop) {
    case 'padded':
      return MaterialTapTargetSize.padded;
    case 'shrinkWrap':
      return MaterialTapTargetSize.shrinkWrap;
    default:
      return null;
  }
}
