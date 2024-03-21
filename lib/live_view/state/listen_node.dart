class ListenNode {
  ListenNode(this.key, [this.component]);

  final String key;
  final String? component;
  get isComponent => component != null;

  @override
  bool operator ==(Object other) {
    if (other is! ListenNode) return false;
    if (key != other.key) return false;
    if (component != other.component) return false;
    return true;
  }

  @override
  int get hashCode {
    var result = 17;
    result = 37 * result + key.hashCode;
    result = 37 * result + component.hashCode;
    return result;
  }

  @override
  String toString() {
    return 'ListenNode{key: $key, component: $component, isComponent: $isComponent}';
  }
}
