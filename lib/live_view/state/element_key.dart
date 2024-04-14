class ElementKey {
  ElementKey(this.key);

  final String key;

  @override
  bool operator ==(Object other) {
    if (other is! ElementKey) return false;
    if (key != other.key) return false;
    return true;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() {
    return 'ElementKey{key: $key}';
  }
}
