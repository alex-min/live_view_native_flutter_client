import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDynamicComponent extends LiveStateWidget<LiveDynamicComponent> {
  const LiveDynamicComponent({super.key, required super.state});

  @override
  State<LiveDynamicComponent> createState() => _LiveDynamicComponentState();
}

class _LiveDynamicComponentState extends StateWidget<LiveDynamicComponent> {
  Map<String, dynamic> lastLiveDiff = {};

  List<Widget>? child;

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
    List<Widget> children = [];
    for (ElementKey elementKey in extraKeysListened) {
      var result = _handleElementKey(elementKey);
      if (result != null) {
        children.add(result);
      }
    }

    if (children.isNotEmpty) {
      child = children;
    }

    return body(child ?? [LiveText(state: widget.state)]);
  }

  Widget? _handleElementKey(ElementKey elementKey) {
    var diffEntry = elementKey.isComponent
        ? lastLiveDiff['c'][elementKey.component][elementKey.key]
        : lastLiveDiff[elementKey.key];

    if (diffEntry is String && diffEntry.trim() == '') {
      return const SizedBox.shrink();
    }

    if (diffEntry is Map) {
      return _handleMapDiffEntry(diffEntry, elementKey);
    }
    return null;
  }

  Widget? _handleMapDiffEntry(Map diffEntry, ElementKey elementKey) {
    if (!diffEntry.containsKey('s')) {
      // only updating child props
      return null;
    }

    var newState = List<String>.from(widget.state.nestedState);

    if (!newState.contains('c') && elementKey.isComponent) {
      newState.add('c');
      newState.add(elementKey.component!);
    }

    newState.add(elementKey.key);

    return body(widget.state.parser
        .parseHtml(
          List<String>.from(diffEntry['s']),
          Map<String, dynamic>.from(diffEntry),
          newState,
        )
        .$1);
  }
}
