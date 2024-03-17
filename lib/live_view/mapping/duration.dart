Duration? getDuration(String? prop) {
  if (prop == null) {
    return null;
  }
  var parse = int.tryParse(prop);
  if (parse == null) {
    return null;
  }
  return Duration(milliseconds: parse);
}
