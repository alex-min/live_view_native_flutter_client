import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class When {
  String conditions;
  When({this.conditions = ""});

  bool get isNotEmpty => conditions.isNotEmpty;

  bool _calculateCondition(double first, String operator, double second) {
    switch (operator) {
      case '>':
        return first > second;
      case '<':
        return first < second;
      case '>=':
        return first >= second;
      case '<=':
        return first <= second;
      case '==':
        return first == second;
      case '!=':
        return first != second;
      default:
        return false;
    }
  }

  bool _execute(List<dynamic> conditions) {
    var stack = [];
    while (conditions.length > 1) {
      var chunk = conditions[0];
      if (chunk is double) {
        var first = conditions.removeAt(0);
        var operator = conditions.removeAt(0);
        var second = conditions.removeAt(0);
        stack.insert(0, _calculateCondition(first, operator, second));
      } else if (chunk is String) {
        switch (chunk) {
          case 'and':
            var restOfCalculation =
                _execute(conditions.getRange(1, conditions.length).toList());
            return stack.first && restOfCalculation;
          case 'or':
            var restOfCalculation =
                _execute(conditions.getRange(1, conditions.length).toList());
            return stack.first || restOfCalculation;
          default:
            return false;
        }
      }
    }
    return stack.first;
  }

  bool execute(BuildContext context) {
    if (conditions.isEmpty) {
      return true;
    }
    var trimmed = conditions.trim();
    switch (trimmed) {
      case 'screen-xs':
        return MediaQuery.of(context).size.width < 576;
      case 'screen-sm':
        return MediaQuery.of(context).size.width >= 576;
      case 'screen-md':
        return MediaQuery.of(context).size.width >= 768;
      case 'screen-lg':
        return MediaQuery.of(context).size.width >= 992;
      case 'screen-xl':
        return MediaQuery.of(context).size.width >= 1200;
      case 'screen-2xl':
        return MediaQuery.of(context).size.width >= 1400;
      default:
        var window = MediaQuery.of(context);
        conditions =
            conditions.replaceAll('window_width', window.size.width.toString());
        conditions = conditions.replaceAll(
            'window_height', window.size.height.toString());

        var c = conditions.split(' ');

        c.removeWhere((element) => element == '');

        return _execute(c.map((op) => double.tryParse(op) ?? op).toList());
    }
  }

  static When parse(String attributeName, Map<String, dynamic>? attributes) {
    String? when = attributes?["$attributeName-when"]?.trim();
    if (when != null) {
      return When(conditions: when);
    }
    return When();
  }
}
