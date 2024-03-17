import 'package:flutter/material.dart';

FloatingActionButtonLocation? getFloatingActionButtonLocation(String? prop) {
  switch (prop) {
    case 'centerDocked':
      return FloatingActionButtonLocation.centerDocked;
    case 'centerFloat':
      return FloatingActionButtonLocation.centerFloat;
    case 'centerTop':
      return FloatingActionButtonLocation.centerTop;
    case 'endContained':
      return FloatingActionButtonLocation.endContained;
    case 'endDocked':
      return FloatingActionButtonLocation.endDocked;
    case 'endFloat':
      return FloatingActionButtonLocation.endFloat;
    case 'endTop':
      return FloatingActionButtonLocation.endTop;
    case 'miniCenterDocked':
      return FloatingActionButtonLocation.miniCenterDocked;
    case 'miniCenterFloat':
      return FloatingActionButtonLocation.miniCenterFloat;
    case 'eeminiCenterTop':
      return FloatingActionButtonLocation.miniCenterTop;
    case 'miniEndDocked':
      return FloatingActionButtonLocation.miniEndDocked;
    case 'miniEndFloat':
      return FloatingActionButtonLocation.miniEndFloat;
    case 'miniEndTop':
      return FloatingActionButtonLocation.miniEndTop;
    case 'miniStartDocked':
      return FloatingActionButtonLocation.miniStartDocked;
    case 'miniStartFloat':
      return FloatingActionButtonLocation.miniStartFloat;
    case 'miniStartTop':
      return FloatingActionButtonLocation.miniStartTop;
    case 'startDocked':
      return FloatingActionButtonLocation.startDocked;
    case 'startFloat':
      return FloatingActionButtonLocation.startFloat;
    case 'startTop':
      return FloatingActionButtonLocation.startTop;
    default:
      return null;
  }
}
