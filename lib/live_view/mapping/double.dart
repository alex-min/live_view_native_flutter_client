double? getDouble(String? property) {
  if (property == null) {
    return null;
  }
  return double.tryParse(property);
}
