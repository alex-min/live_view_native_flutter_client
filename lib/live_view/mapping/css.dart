List<(String, String)> parseCss(String style) {
  var styleList = style.trim().replaceAll(r'/ *\; */', ' ').split(' ')
    ..removeWhere((e) => e == '');
  if (styleList.isEmpty) {
    return [];
  }

  // the last one is considered invalid
  if (styleList.length % 2 == 1) {
    styleList.removeLast();
  }

  List<(String, String)> css = [];
  for (var i = 0; i < styleList.length; i += 2) {
    var styleKey = styleList[i].replaceAll(':', '');
    var styleValue = styleList[i + 1].replaceAll(';', '');

    css.add((styleKey, styleValue));
  }
  return css;
}
