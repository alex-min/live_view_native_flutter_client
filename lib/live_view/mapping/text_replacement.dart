import 'package:xml/xml.dart';

String replaceVariables(String content, Map<String, dynamic> variables) {
  for (var item in variables.entries) {
    content = content.replaceAll(
        '<flutterState key="${item.key}"></flutterState>',
        item.value.toString());
    content = content.replaceAll(
        '[[flutterState key=${item.key}]]', item.value.toString());
  }
  return content;
}

List<String> extractDynamicKeys(String input) {
  var matches =
      RegExp(r'\[\[flutterState key=(?<key>\d)\]\]').allMatches(input);
  List<String> ret = [];
  for (var match in matches) {
    var key = match.group(1);
    if (key != null && !ret.contains(key)) {
      ret.add(key);
    }
  }

  return ret;
}

(String?, String?) getVariableAttribute(
  XmlNode node,
  String attribute,
  Map<String, dynamic> variables,
) {
  var attr = node.getAttribute(attribute);
  if (attr == null) {
    return (null, null);
  }
  var matches = RegExp(r'\[\[flutterState key=(?<key>\d)\]\]').firstMatch(attr);
  var key = matches?.group(1);

  if (key != null && variables[key] != null) {
    var content = "${variables[key]}".trimLeft();

    content = content.replaceFirst('$attribute="', '');
    if (content[content.length - 1] == '"') {
      content = content.substring(0, content.length - 1);
    }
    return (attr.replaceAll("[[flutterState key=$key]]", content), key);
  }
  if (attr[0] == '[' && attr[attr.length - 1] == ']') {}
  return (attr, null);
}

class VariableAttributes {
  Map<String, String?> attributes;
  List<String> keys;

  VariableAttributes(this.attributes, this.keys);
}

VariableAttributes getVariableAttributes(
  XmlNode node,
  List<String> attributes,
  Map<String, dynamic> variables,
) {
  var ret = VariableAttributes({}, []);

  for (var attribute in attributes) {
    var (value, key) = getVariableAttribute(node, attribute, variables);
    ret.attributes[attribute] = value;
    if (key != null && !ret.keys.contains(key)) {
      ret.keys.add(key);
    }
  }
  return ret;
}
