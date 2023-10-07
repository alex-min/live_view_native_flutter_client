import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDynamicComponent extends LiveStateWidget {
  const LiveDynamicComponent({super.key, required super.state});

  @override
  State<LiveDynamicComponent> createState() => _LiveDynamicComponentState();
}

class _LiveDynamicComponentState extends StateWidget<LiveDynamicComponent> {
  Map<String, dynamic> lastLiveDiff = {};

  Widget? child;

  @override
  void onStateChange(Map<String, dynamic> diff) {
    lastLiveDiff = diff;
    listenInnerTextKeys();
    if (extraKeysListened.isNotEmpty) {
      if (lastLiveDiff.containsKey(extraKeysListened[0]) &&
          lastLiveDiff[extraKeysListened[0]] == '') {
        child = null;
      }
    }
  }

  @override
  void onReconnect() {
    child = null;
    super.onReconnect();
  }

  @override
  Widget render(BuildContext context) {
    var text = widget.state.node.toString().trim();
    if (text == '') {
      return child ?? const SizedBox.shrink();
    }

    for (var key in extraKeysListened) {
      if (lastLiveDiff[key] is Map) {
        // new component
        if (lastLiveDiff[key].containsKey('s')) {
          var newState = List<int>.from(widget.state.nestedState);
          newState.add(int.parse(key));
          child = widget.state.parser.parseHtml(
              List<String>.from(lastLiveDiff[key]['s']),
              Map<String, dynamic>.from(lastLiveDiff[key]),
              newState);
          return child!;
        } else {
          // only updating child props
          return child ?? const SizedBox.shrink();
        }
      } else {
        // in-text replacement
        if (lastLiveDiff[key] is String && lastLiveDiff[key].trim() == '') {
          return child ?? const SizedBox.shrink();
        }
        throw Exception('not implemented');
      }
    }

    return child ?? const SizedBox.shrink();
  }
}
