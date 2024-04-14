import 'package:html_unescape/html_unescape.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:xml/xml.dart';

const elementPattern = r'\[\[flutterState\s*key=(\d+)?\]\]';

String replaceVariables(String content, Map<String, dynamic> variables) {
  return content.replaceAllMapped(RegExp(elementPattern), (match) {
    var value = variables[match.group(1)];

    if (value is Map && value.containsKey('s')) {
      return List<String>.from(value['s'])
          .joinWith((i) => value[i.toString()].toString());
    }

    return value?.toString() ?? '';
  });
}

List<ElementKey> extractDynamicKeys(String input) {
  var matches = RegExp(elementPattern).allMatches(input);
  List<ElementKey> ret = [];
  for (var match in matches) {
    if (match.group(1) == null) {
      continue;
    }
    final elementKey = ElementKey(match.group(1)!);
    if (!ret.contains(elementKey)) {
      ret.add(elementKey);
    }
  }

  return ret;
}

(String?, ElementKey?) getVariableAttribute(
  XmlNode node,
  String attribute,
  Map<String, dynamic> variables,
) {
  var attr = node.getAttribute(attribute);
  if (attr == null) {
    return (null, null);
  }

  var matches = RegExp(elementPattern).firstMatch(attr);
  if (matches == null) {
    return (attr, null);
  }

  var elementKey = ElementKey(matches.group(1)!);
  if (variables[elementKey.key] == null) {
    return (attr, null);
  }

  var content = "${variables[elementKey.key]}".replaceFirstMapped(
    RegExp("^\\s*$attribute=\"(.*)\"\\s*\$"),
    (m) => "${m[1]}",
  );

  return (
    attr.replaceAll("[[flutterState key=${elementKey.key}]]", content),
    elementKey
  );
}

class VariableAttributes {
  Map<String, String?> attributes;
  List<ElementKey> listenedKeys;

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
