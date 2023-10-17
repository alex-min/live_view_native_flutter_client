bool? getBoolean(String? prop) {
  switch (prop) {
    case 'true':
      return true;
    case 'false':
      return false;
    default:
      return null;
  }
}
