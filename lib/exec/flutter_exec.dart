import 'dart:convert';

import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_go_back.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/exec_live_patch.dart';
import 'package:liveview_flutter/exec/exec_phx_href.dart';
import 'package:liveview_flutter/exec/exec_save_current_theme.dart';
import 'package:liveview_flutter/exec/exec_show_bottom_sheet.dart';
import 'package:liveview_flutter/exec/exec_switch_theme.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:liveview_flutter/when/when.dart';

class FlutterExecAction {
  String name;
  Map<String, dynamic>? value;

  FlutterExecAction({required this.name, this.value});

  @override
  String toString() => 'FlutterExecAction(name: $name, value: $value)';

  dynamic toJson() => [name, value];

  Map<String, dynamic> phxValues(Map<String, dynamic>? attributes) {
    return Map<String, dynamic>.fromEntries(attributes?.entries
            .where((e) => e.key.startsWith('phx-value'))
            .map((e) {
          return MapEntry(e.key.replaceFirst('phx-value-', ''), e.value);
        }) ??
        {});
  }

  Exec parse(String attributeName, Map<String, dynamic>? attributes) {
    Exec exec = _getExec(attributes);
    exec.conditions = When.parse(attributeName, attributes);
    return exec;
  }

  Exec _getExec(Map<String, dynamic>? attributes) {
    switch (name) {
      case 'phx-click':
        return ExecLiveEvent(
            type: 'phx-click',
            name: value!['name'],
            value: phxValues(attributes));
      case 'live-patch':
        return ExecLivePatch(url: value!['name']);
      case 'phx-href':
        return ExecPhxHref(url: value!['name']);
      case 'goBack':
        return ExecGoBack();
      case 'switchTheme':
        return ExecSwitchTheme(theme: value!['theme'], mode: value!['mode']);
      case 'saveCurrentTheme':
        return ExecSaveCurrentTheme();
      case 'show':
        return ExecShowAction(
            to: value?['to'], timeInMilliseconds: value?['time']);
      case 'hide':
        return ExecHideAction(
            to: value?['to'], timeInMilliseconds: value?['time']);
      case 'showBottomSheet':
        return ExecShowBottomSheet();
    }

    // using a just string triggers a server event
    return ExecLiveEvent(
        type: 'event', name: value!['name'], value: phxValues(attributes));
  }
}

class FlutterExec {
  static String encode(List<FlutterExecAction> actions) =>
      const HtmlEscape().convert(jsonEncode(actions));

  static List<Exec> parse(String? attribute, String attributeName,
      Map<String, dynamic>? attributes) {
    if (attribute == null) {
      return [];
    }

    List? actionList = tryJsonDecode(attribute);
    if (actionList == null) {
      return [
        FlutterExecAction(name: attributeName, value: {'name': attribute})
            .parse(attributeName, attributes)
      ];
    }

    List<Exec> ret = [];

    for (var action in actionList) {
      ret.add(FlutterExecAction(name: action[0], value: action[1]).parse(
        attributeName,
        attributes,
      ));
    }
    return ret;
  }
}
