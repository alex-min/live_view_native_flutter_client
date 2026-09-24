import 'package:flutter/material.dart';

const _centerDockedWithoutBar = _CenterDockedWithoutBarLocation();
const _material3BottomAppBarHeight = 80.0;

FloatingActionButtonLocation? getFloatingActionButtonLocation(String? prop) {
  switch (prop) {
    case 'centerDocked':
      return FloatingActionButtonLocation.centerDocked;
    case 'centerFloat':
      return FloatingActionButtonLocation.centerFloat;
    case 'centerDockedWithoutBar':
      return _centerDockedWithoutBar;
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

/// Places a standalone FAB where a center-docked FAB would sit if the standard
/// bottom navigation bar were present, without reserving or painting a bar.
class _CenterDockedWithoutBarLocation extends FloatingActionButtonLocation {
  const _CenterDockedWithoutBarLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final fabSize = scaffoldGeometry.floatingActionButtonSize;
    final x = (scaffoldGeometry.scaffoldSize.width - fabSize.width) / 2;
    final dockLine =
        scaffoldGeometry.contentBottom -
        _material3BottomAppBarHeight -
        scaffoldGeometry.minViewPadding.bottom;
    final maxY =
        scaffoldGeometry.scaffoldSize.height -
        fabSize.height -
        scaffoldGeometry.minViewPadding.bottom;
    final y = (dockLine - fabSize.height / 2).clamp(
      scaffoldGeometry.minViewPadding.top,
      maxY,
    );

    return Offset(x, y.toDouble());
  }
}
