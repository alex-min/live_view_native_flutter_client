import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:xml/xml.dart';

mixin ComputedAttributes {
  VariableAttributes computedAttributes = VariableAttributes({}, []);
  List<String> extraKeysListened = [];
  var defaultListenedKeys = [
    'phx-click',
    'id',
    'live-patch',
    'phx-before-each-render'
  ];
  Map<String, dynamic> currentVariables = {};

  bool isKeyListened(String key) =>
      computedAttributes.keys.contains(key) || extraKeysListened.contains(key);

  void addListenedKey(String key) {
    if (!extraKeysListened.contains(key)) {
      extraKeysListened.add(key);
    }
  }

  String? getAttribute(String name) {
    if (computedAttributes.attributes.containsKey(name)) {
      var attribute = computedAttributes.attributes[name];
      if (attribute == null) {
        return null;
      }
      return attribute;
    }
    return null;
  }

  void reloadPredefinedAttributes(XmlNode node) {
    for (var attribute in node.attributes) {
      var name = attribute.name.toString();
      if (name.startsWith('phx-') && !defaultListenedKeys.contains(name)) {
        defaultListenedKeys.add(name);
      }
    }

    var attrs =
        getVariableAttributes(node, defaultListenedKeys, currentVariables);
    computedAttributes.merge(attrs);
  }

  void reloadAttributes(XmlNode node, List<String> attributes) {
    computedAttributes =
        getVariableAttributes(node, attributes, currentVariables);
  }
}
