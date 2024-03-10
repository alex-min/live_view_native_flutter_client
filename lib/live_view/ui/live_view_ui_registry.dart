import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

typedef WidgetBuilder = List<Widget> Function(NodeState);

class LiveViewUiRegistry {
  LiveViewUiRegistry._internal();

  static final LiveViewUiRegistry _instance = LiveViewUiRegistry._internal();

  final Map<String, WidgetBuilder> _widgets = {};

  static LiveViewUiRegistry get instance => _instance;

  void add(List<String> componentNames, WidgetBuilder buildWidget) {
    for (var componentName in componentNames) {
      _widgets[componentName] = buildWidget;
    }
  }

  List<Widget> buildWidget(String componentName, NodeState state) {
    if (_widgets.containsKey(componentName)) {
      return _widgets[componentName]!.call(state);
    }

    reportError("unknown widget $componentName");
    return [const SizedBox.shrink()];
  }
}
