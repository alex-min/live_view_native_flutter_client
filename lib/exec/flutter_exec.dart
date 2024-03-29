import 'dart:convert';

import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_confirmable.dart';
import 'package:liveview_flutter/exec/exec_go_back.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/exec_live_patch.dart';
import 'package:liveview_flutter/exec/exec_phx_href.dart';
import 'package:liveview_flutter/exec/exec_save_current_theme.dart';
import 'package:liveview_flutter/exec/exec_show_bottom_sheet.dart';
import 'package:liveview_flutter/exec/exec_switch_theme.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:liveview_flutter/when/when.dart';

Map<String, dynamic> getPhxValues(Map<String, dynamic>? attributes) {
  return Map<String, dynamic>.fromEntries(
      attributes?.entries.where((e) => e.key.startsWith('phx-value')).map((e) {
            return MapEntry(e.key.replaceFirst('phx-value-', ''), e.value);
          }) ??
          {});
}

class FlutterExecAction {
  String name;
  Map<String, dynamic>? value;

  FlutterExecAction({required this.name, this.value});

  @override
  String toString() => 'FlutterExecAction(name: $name, value: $value)';

  dynamic toJson() => [name, value];

  Map<String, dynamic> phxValues(Map<String, dynamic>? attributes) =>
      getPhxValues(attributes);

  Exec parse(String attributeName, Map<String, dynamic>? attributes) {
    Exec exec = _getExec(attributes);
    exec.conditions = When.parse(attributeName, attributes);
    return exec;
  }

  Exec _getExec(Map<String, dynamic>? attributes) {
    final exec = LiveViewExecRegistry.instance
        .exec(name, value: value, attributes: attributes);

    if (exec != null) {
      return exec;
    }

    // using a just string triggers a server event
    return ExecLiveEvent(
        type: 'event', name: value!['name'], value: phxValues(attributes));
  }

  static void registerDefaultExecs() {
    LiveViewExecRegistry.instance
      ..add(['phx-click'], (value, attributes) {
        return ExecLiveEvent(
          type: 'phx-click',
          name: value!['name'],
          value: getPhxValues(attributes),
          dataConfirm:
              (attributes?['data-confirm'] as String?)?.isNotEmpty == true
                  ? DataConfirm(
                      message: attributes!['data-confirm'],
                      title: attributes['data-confirm-title'],
                      cancel: attributes['data-confirm-cancel'],
                      confirm: attributes['data-confirm-confirm'],
                    )
                  : null,
        );
      })
      ..add(['live-patch'], (value, attributes) {
        return ExecLivePatch(url: value!['name']);
      })
      ..add(['phx-href'], (value, attributes) {
        return ExecPhxHref(url: value!['name']);
      })
      ..add(['phx-href-modal'], (value, attributes) {
        return ExecPhxHrefModal(url: value!['name']);
      })
      ..add(['goBack'], (_, __) => ExecGoBack())
      ..add(['switchTheme'], (value, attributes) {
        return ExecSwitchTheme(
          theme: value!['theme'],
          mode: value['mode'],
        );
      })
      ..add(['saveCurrentTheme'], (_, __) => ExecSaveCurrentTheme())
      ..add(['show'], (value, attributes) {
        return ExecShowAction(
          to: value?['to'],
          timeInMilliseconds: value?['time'],
        );
      })
      ..add(['hide'], (value, attributes) {
        return ExecHideAction(
          to: value?['to'],
          timeInMilliseconds: value?['time'],
        );
      })
      ..add(['showBottomSheet'], (_, __) => ExecShowBottomSheet());
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
