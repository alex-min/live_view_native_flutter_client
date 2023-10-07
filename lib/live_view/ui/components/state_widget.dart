import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:provider/provider.dart';

enum HandleClickState { automatic, manual }

abstract class LiveStateWidget<T extends StatefulWidget>
    extends StatefulWidget {
  final NodeState state;
  const LiveStateWidget({super.key, required this.state});
}

abstract class StateWidget<T extends LiveStateWidget> extends State<T> {
  late StateNotifier stateNotifier;
  late Map<String, dynamic> currentVariables;
  late VariableAttributes computedAttributes;
  late LiveConnectionNotifier connectionNotifier;
  late List<String> extraKeysListened;
  bool forceReconnectRefresh = false;

  @override
  void initState() {
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    computedAttributes = VariableAttributes({}, []);
    extraKeysListened = [];
    onStateChange(currentVariables);
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);
    stateNotifier.addListener(onDiffUpdateEvent);
    connectionNotifier =
        Provider.of<LiveConnectionNotifier>(context, listen: false)
          ..addListener(onReconnect);
    super.initState();
  }

  @override
  void dispose() {
    stateNotifier.removeListener(onDiffUpdateEvent);
    connectionNotifier.removeListener(onReconnect);
    super.dispose();
  }

  void onReconnect() {
    if (!mounted) {
      return;
    }
    currentVariables = Map.from(widget.state.variables);
    computedAttributes = VariableAttributes({}, []);
    onStateChange(currentVariables);
    forceReconnectRefresh = true;
    setState(() {});
  }

  void onStateChange(Map<String, dynamic> diff);

  void onDiffUpdateEvent() {
    if (!mounted) {
      return;
    }
    var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);
    if (lastLiveDiff.keys.any((key) => isKeyListened(key)) ||
        forceReconnectRefresh) {
      currentVariables.addAll(lastLiveDiff);
      forceReconnectRefresh = false;
      onStateChange(lastLiveDiff);
      setState(() {});
    }
  }

  bool isKeyListened(String key) =>
      computedAttributes.keys.contains(key) || extraKeysListened.contains(key);

  void reloadAttributes(List<String> attributes) {
    attributes.add('phx-click');
    computedAttributes =
        getVariableAttributes(widget.state.node, attributes, currentVariables);
  }

  void addListenedKey(String key) {
    if (!extraKeysListened.contains(key)) {
      extraKeysListened.add(key);
    }
  }

  String? getAttribute(String name) {
    if (computedAttributes.attributes.containsKey(name)) {
      return computedAttributes.attributes[name];
    }
    return null;
  }

  Widget singleChild({NodeState? state}) {
    state ??= widget.state;
    var children = state.node.nonEmptyChildren;
    switch (children.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return state.parser.traverse(state.copyWith(node: children[0]));
      default:
        return Column(children: multipleChildren(state: state));
    }
  }

  List<Widget> multipleChildren({NodeState? state}) {
    state ??= widget.state;
    return state.node.nonEmptyChildren
        .map((child) => state!.parser.traverse(state.copyWith(node: child)))
        .toList();
  }

  Type? extractChild<Type extends Widget>(List<Widget> children) {
    Type? ret;
    for (var child in children) {
      if (child is Type) {
        ret = child;
      }
    }
    children.removeWhere((e) => e is Type);

    return ret;
  }

  void handlePhxClick() {
    if (handleClickState() == HandleClickState.automatic) {
      throw Exception("""
            handlePhxClick() manually triggered but handleClickState() is configured on automatic.
            Automatic handling is using Absorbpointer whereas the manual handling is up to the component.
          """);
    }
    var phxClick = getAttribute('phx-click');
    if (phxClick != null) {
      widget.state.parser.phxClick(phxClick);
    }
  }

  @override
  Widget build(BuildContext context) {
    return render(context);
  }

  Widget render(BuildContext context);

  HandleClickState handleClickState() {
    return HandleClickState.automatic;
  }

  LiveView get liveView => widget.state.liveView;

  void listenInnerTextKeys() {
    for (var key in extractDynamicKeys(widget.state.node.toString())) {
      addListenedKey(key);
    }
  }

  Widget body(List<Widget> children) {
    switch (children.length) {
      case 0:
        return const SizedBox.shrink();
      case 1:
        return children[0];
      default:
        return Column(children: children);
    }
  }
}
