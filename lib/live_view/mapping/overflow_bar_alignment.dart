import 'package:flutter/material.dart';

OverflowBarAlignment? getOverflowBarAlignment(String? prop) {
  switch (prop) {
    case 'center':
      return OverflowBarAlignment.center;
    case 'end':
      return OverflowBarAlignment.end;
    case 'start':
      return OverflowBarAlignment.start;
    default:
      return null;
  }
}
