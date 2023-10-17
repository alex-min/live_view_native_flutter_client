import 'dart:convert';

import 'package:html/parser.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class FlutterExecAction {
  String name;
  Map<String, dynamic>? value;

  FlutterExecAction({required this.name, this.value});

  @override
  String toString() => 'FlutterExecAction(name: $name, value: $value)';

  dynamic toJson() => [name, value];
}

class FlutterExec {
  static String encode(List<FlutterExecAction> actions) =>
      const HtmlEscape().convert(jsonEncode(actions));

  static List<FlutterExecAction> parse(String? attribute, String defaultEvent) {
    if (attribute == null) {
      return [];
    }
    var decodedText = (parseFragment(attribute).text);
    if (decodedText == null) {
      return [
        FlutterExecAction(name: defaultEvent, value: {'name': attribute})
      ];
    }
    List? actionList = tryJsonDecode(decodedText);
    if (actionList == null) {
      return [
        FlutterExecAction(name: defaultEvent, value: {'name': attribute})
      ];
    }

    List<FlutterExecAction> ret = [];

    for (var action in actionList) {
      ret.add(FlutterExecAction(name: action[0], value: action[1]));
    }
    return ret;
  }
}
