import 'package:flutter/material.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

var flutterJs = getJavascriptRuntime(xhr: false);

class When {
  String conditions;
  When({this.conditions = ""});

  bool get isNotEmpty => conditions.isNotEmpty;

  bool execute(BuildContext context) {
    if (conditions.isEmpty) {
      return true;
    }
    conditions = conditions.replaceAll(
        'window_width', MediaQuery.of(context).size.width.toString());
    conditions = conditions.replaceAll(
        'window_height', MediaQuery.of(context).size.height.toString());

    return flutterJs.evaluate(conditions).rawResult;
  }

  static When parse(String attributeName, Map<String, dynamic>? attributes) {
    String? when = attributes?["$attributeName-when"]?.trim();
    if (when != null) {
      return When(conditions: when);
    }
    // todo parse
    return When();
  }
}
