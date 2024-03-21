import 'package:html_unescape/html_unescape.dart';
import 'package:liveview_flutter/live_view/state/listen_node.dart';
import 'package:xml/xml.dart';

String replaceVariables(String content, Map<String, dynamic> variables) {
  final components = Map<String, dynamic>.from(variables["c"] ?? {});
  for (var item in variables.entries) {
    content = content.replaceAll(
        '<flutterState key="${item.key}"></flutterState>',
        item.value.toString());
    content = content.replaceAll(
        '[[flutterState key=${item.key}]]', item.value.toString());

    for (var componentId in components.keys) {
      content = content.replaceAll(
          "[[flutterState key=${item.key} component=$componentId]]",
          components[componentId]?[item.key]?.toString() ?? "");
    }
  }
  content = content.replaceAll(RegExp(r'\[\[flutterState key=\d+\]\]'), '');
  return content;
}

List<ListenNode> extractDynamicKeys(String input) {
  var matches = RegExp(
          r'\[\[flutterState key=(?<key>\d+)(?: component=(?<component>\d+))?\]\]')
      .allMatches(input);
  List<ListenNode> ret = [];
  for (var match in matches) {
    var key = match.group(1);
    var component = match.group(2);
    if (key != null && !ret.contains(key)) {
      ret.add(ListenNode(key, component));
    }
  }

  return ret;
}

(String?, ListenNode?) getVariableAttribute(
  XmlNode node,
  String attribute,
  Map<String, dynamic> variables,
) {
  var attr = node.getAttribute(attribute);
  if (attr == null) {
    return (null, null);
  }
  var matches =
      RegExp(r'\[\[flutterState key=(?<key>\d+)\]\]').firstMatch(attr);
  var key = matches?.group(1);

  if (key != null && variables[key] != null) {
    var content = "${variables[key]}".trimLeft();

    if (content.contains('$attribute="')) {
      content = content.replaceFirst('$attribute="', '');
      if (content[content.length - 1] == '"') {
        content = content.substring(0, content.length - 1);
      }
    }
    return (
      attr.replaceAll("[[flutterState key=$key]]", content),
      ListenNode(key)
    );
  }
  return (attr, null);
}

class VariableAttributes {
  Map<String, String?> attributes;
  List<ListenNode> listenedKeys;

  VariableAttributes(this.attributes, this.listenedKeys);

  void merge(VariableAttributes other) {
    for (var key in other.listenedKeys) {
      if (!listenedKeys.contains(key)) {
        listenedKeys.add(key);
      }
    }

    attributes.addAll(other.attributes);
  }
}

VariableAttributes getVariableAttributes(
  XmlNode node,
  List<String> attributes,
  Map<String, dynamic> variables,
) {
  var ret = VariableAttributes({}, []);

  for (var attribute in attributes) {
    var (value, key) = getVariableAttribute(node, attribute, variables);
    ret.attributes[attribute] =
        value != null ? HtmlUnescape().convert(value) : null;
    if (key != null && !ret.listenedKeys.contains(key)) {
      ret.listenedKeys.add(key);
    }
  }
  return ret;
}
