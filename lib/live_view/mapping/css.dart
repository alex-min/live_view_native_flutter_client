extension StringX on String {
  isLetterOrNumber() {
    var val = codeUnitAt(0);
    return (val >= 97 && val <= 122) ||
        (val >= 65 && val <= 90) ||
        (val >= 48 && val <= 57);
  }
}

List<(String, String)> parseCss(String style) {
  style = style.replaceAll("\n", "");
  var currentToken = 0;
  List<String> css = [];

  while (currentToken < style.length) {
    if (style[currentToken].isLetterOrNumber()) {
      var from = currentToken;
      while (currentToken < style.length &&
          style[currentToken].isLetterOrNumber()) {
        currentToken++;
      }
      css.add(style.substring(from, currentToken));
    } else if (style[currentToken] == '{') {
      currentToken++;
      var from = currentToken;
      var count = 1;
      while (count != 0 && currentToken < style.length) {
        if (style[currentToken] == '{') {
          count++;
        } else if (style[currentToken] == '}') {
          count--;
        }
        currentToken++;
      }
      if (count == 0) {
        currentToken--;
      }
      css.add(style.substring(from, currentToken).trim());
    } else {
      currentToken++;
    }
  }

  // invalid css, we remove the last property
  if (css.length % 2 == 1) {
    css.removeLast();
  }

  List<(String, String)> ret = [];
  for (var i = 0; i < css.length; i += 2) {
    ret.add((css[i], css[i + 1]));
  }
  return ret;
}
