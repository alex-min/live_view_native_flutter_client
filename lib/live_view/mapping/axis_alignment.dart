import 'package:flutter/material.dart';

MainAxisAlignment? getMainAxisAlignment(String? prop) {
  switch (prop) {
    case 'center':
      return MainAxisAlignment.center;
    case 'start':
      return MainAxisAlignment.start;
    case 'end':
      return MainAxisAlignment.end;
    case 'spaceAround':
      return MainAxisAlignment.spaceAround;
    case 'spaceBetween':
      return MainAxisAlignment.spaceBetween;
    case 'spaceEvenly':
      return MainAxisAlignment.spaceEvenly;
    default:
      return null;
  }
}

MainAxisSize? getMainAxisSize(String? prop) {
  switch (prop) {
    case 'max':
      return MainAxisSize.max;
    case 'min':
      return MainAxisSize.min;
    default:
      return null;
  }
}

CrossAxisAlignment? getCrossAxisAlignment(String? prop) {
  switch (prop) {
    case 'center':
      return CrossAxisAlignment.center;
    case 'start':
      return CrossAxisAlignment.start;
    case 'end':
      return CrossAxisAlignment.end;
    case 'baseline':
      return CrossAxisAlignment.baseline;
    case 'stretch':
      return CrossAxisAlignment.stretch;
    default:
      return null;
  }
}

VerticalDirection? getVerticalDirection(String? prop) {
  switch (prop) {
    case 'down':
      return VerticalDirection.down;
    case 'up':
      return VerticalDirection.up;
    default:
      return null;
  }
}
