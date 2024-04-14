import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

mixin ComputedAttributes {
  VariableAttributes computedAttributes = VariableAttributes({}, []);
  List<ElementKey> extraKeysListened = [];
  var defaultListenedAttributes = [
    'phx-click',
    'id',
    'live-patch',
    'phx-href',
    'phx-before-each-render',
    'data-confirm',
    'data-confirm-title',
    'data-confirm-cancel',
    'data-confirm-confirm',
    'self-padding',
    'self-margin'
  ];
  Map<String, dynamic> currentVariables = {};

  bool isKeyListened(ElementKey key) =>
      computedAttributes.listenedKeys.contains(key) ||
      extraKeysListened.contains(key);

  void addListenedKey(ElementKey key) {
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
      if (name.startsWith('phx-') &&
          !defaultListenedAttributes.contains(name)) {
        defaultListenedAttributes.add(name);
      }
    }

    var attrs = getVariableAttributes(
        node, defaultListenedAttributes, currentVariables);
    computedAttributes.merge(attrs);
  }

  void reloadAttributes(XmlNode node, List<String> attributes) {
    computedAttributes =
        getVariableAttributes(node, attributes, currentVariables);
  }

  Map<String, String?> bindChildVariableAttributes(XmlNode node,
      List<String> attributes, Map<String, dynamic> stateVariables) {
    for (var attribute in node.attributes) {
      var name = attribute.name.toString();
      if ((name.startsWith('phx-') ||
              defaultListenedAttributes.contains(name)) &&
          !attributes.contains(name)) {
        attributes.add(name);
      }
    }
    var ret = getVariableAttributes(node, attributes, stateVariables);
    for (var key in ret.listenedKeys) {
      if (!extraKeysListened.contains(key)) {
        extraKeysListened.add(key);
      }
    }

    return ret.attributes;
  }

  List<XmlNode> childrenNodesOf(XmlNode node, String componentName) {
    List<XmlNode> ret = [];

    for (var child in node.nonEmptyChildren) {
      if (child.nodeType == XmlNodeType.ELEMENT) {
        if ((child as XmlElement).name.qualified == 'flutter') {
          ret.addAll(childrenNodesOf(child, componentName));
        } else if (child.name.qualified == componentName) {
          ret.add(child);
        }
      }
    }
    return ret;
  }
}
