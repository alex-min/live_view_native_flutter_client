import 'dart:ui';

Clip? getClip(String? prop) {
  switch (prop) {
    case 'antiAlias':
      return Clip.antiAlias;
    case 'antiAliasWithSaveLayer':
      return Clip.antiAliasWithSaveLayer;
    case 'hardEdge':
      return Clip.hardEdge;
    case 'none':
      return Clip.none;
    default:
      return null;
  }
}
