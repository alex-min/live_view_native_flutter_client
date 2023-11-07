import 'dart:ui';

BoxHeightStyle? getBoxHeightStyle(String? prop) {
  switch (prop) {
    case 'includeLineSpacingBottom':
      return BoxHeightStyle.includeLineSpacingBottom;
    case 'includeLineSpacingMiddle':
      return BoxHeightStyle.includeLineSpacingMiddle;
    case 'includeLineSpacingTop':
      return BoxHeightStyle.includeLineSpacingTop;
    case 'max':
      return BoxHeightStyle.max;
    case 'strut':
      return BoxHeightStyle.strut;
    case 'tight':
      return BoxHeightStyle.tight;
    default:
      return null;
  }
}
