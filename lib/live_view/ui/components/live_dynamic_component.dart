import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDynamicComponent extends LiveStateWidget<LiveDynamicComponent> {
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
  void onWipeState() {
    child = null;
    super.onWipeState();
  }

  @override
  Widget render(BuildContext context) {
    var text = widget.state.node.toString().trim();
    if (text == '') {
      return child ?? const SizedBox.shrink();
    }

    for (var listenNode in extraKeysListened) {
      var key = listenNode.key;
      if (listenNode.isComponent && lastLiveDiff.containsKey("c")) {
        if (lastLiveDiff['c'][listenNode.component][listenNode.key] is Map) {
          // new component
          if (lastLiveDiff['c'][listenNode.component][listenNode.key]
              .containsKey('s')) {
            var newState = List<int>.from(widget.state.nestedState);
            newState.add(int.parse(listenNode.key));

            // TODO: handle multiple children passed here and turn it into a column
            child = widget.state.parser
                .parseHtml(
                    List<String>.from(lastLiveDiff['c'][listenNode.component]
                        [listenNode.key]['s']),
                    Map<String, dynamic>.from(lastLiveDiff['c']
                        [listenNode.component][listenNode.key]),
                    newState)
                .$1
                .first;
            return child!;
          }
        } else if (lastLiveDiff['c'][listenNode.component][listenNode.key]
                is String &&
            lastLiveDiff['c'][listenNode.component][listenNode.key].trim() ==
                '') {
          return const SizedBox.shrink();
        }
      } else if (lastLiveDiff[key] is Map) {
        // new component
        if (lastLiveDiff[key].containsKey('s')) {
          var newState = List<int>.from(widget.state.nestedState);
          newState.add(int.parse(listenNode.key));
          // TODO: handle multiple children passed here and turn it into a column
          child = widget.state.parser
              .parseHtml(
                  List<String>.from(lastLiveDiff[listenNode.key]['s']),
                  Map<String, dynamic>.from(lastLiveDiff[listenNode.key]),
                  newState)
              .$1
              .first;
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

        if (lastLiveDiff[key] == null) {
          return child ?? const SizedBox.shrink();
        }

        return child ?? LiveText(state: widget.state);
      }
    }

    return child ?? LiveText(state: widget.state);
  }
}
