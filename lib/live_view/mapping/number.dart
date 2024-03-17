double? getDouble(String? property) {
  if (property == null) {
    return null;
  }
  if (property == 'infinity') {
    return double.infinity;
  }
  return double.tryParse(property);
}

int? getInt(String? property) {
  if (property == null) {
    return null;
  }
  return int.tryParse(property);
}
