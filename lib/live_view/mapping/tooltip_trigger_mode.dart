import 'package:flutter/material.dart';

TooltipTriggerMode? getTooltipTriggerMode(String? prop) {
  switch (prop) {
    case 'longPress':
      return TooltipTriggerMode.longPress;
    case 'manual':
      return TooltipTriggerMode.manual;
    case 'tap':
      return TooltipTriggerMode.tap;
    default:
      return null;
  }
}
