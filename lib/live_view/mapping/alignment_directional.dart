import 'package:flutter/material.dart';

AlignmentDirectional? getAlignmentDirectional(String? prop) {
  switch (prop) {
    case 'bottomCenter':
      return AlignmentDirectional.bottomCenter;
    case 'bottomEnd':
      return AlignmentDirectional.bottomEnd;
    case 'bottomStart':
      return AlignmentDirectional.bottomStart;
    case 'center':
      return AlignmentDirectional.center;
    case 'centerEnd':
      return AlignmentDirectional.centerEnd;
    case 'centerStart':
      return AlignmentDirectional.centerStart;
    case 'topCenter':
      return AlignmentDirectional.topCenter;
    case 'topEnd':
      return AlignmentDirectional.topEnd;
    case 'topStart':
      return AlignmentDirectional.topStart;
    default:
      return null;
  }
}
