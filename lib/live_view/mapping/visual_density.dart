import 'package:flutter/material.dart';

VisualDensity? getVisualDensity(String? prop) {
  switch (prop) {
    case 'adaptivePlatformDensity':
      return VisualDensity.adaptivePlatformDensity;
    case 'comfortable':
      return VisualDensity.comfortable;
    case 'standard':
      return VisualDensity.standard;
    case 'compact':
      return VisualDensity.compact;
    default:
      return null;
  }
}
