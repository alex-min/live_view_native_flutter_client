import 'package:quiver/core.dart';

class ElementKey {
  ElementKey(this.key, [this.component]);

  final String key;
  final String? component;
  get isComponent => component != null;

  @override
  bool operator ==(Object other) {
    if (other is! ElementKey) return false;
    if (key != other.key) return false;
    if (component != other.component) return false;
    return true;
  }

  @override
  int get hashCode => hash2(key, component);

  @override
  String toString() {
    return 'ElementKey{key: $key, component: $component, isComponent: $isComponent}';
  }
}
