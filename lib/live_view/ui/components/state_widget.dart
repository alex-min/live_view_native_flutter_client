import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:provider/provider.dart';

enum Status { visible, hidden }

enum HandleClickState { automatic, manual }

abstract class LiveStateWidget<T extends StatefulWidget>
    extends StatefulWidget {
  final NodeState state;
  const LiveStateWidget({super.key, required this.state});
}

typedef EventHandler = void Function(BuildContext context);

abstract class StateWidget<T extends LiveStateWidget> extends State<T>
    with TickerProviderStateMixin {
  late StateNotifier stateNotifier;
  late Map<String, dynamic> currentVariables;
  late VariableAttributes computedAttributes;
  late LiveConnectionNotifier connectionNotifier;
  late List<String> extraKeysListened;
  bool forceReconnectRefresh = false;
  var defaultListenedKeys = ['phx-click', 'flutter-click', 'id'];
  bool _reloadCalled = false;
  AnimationController? _animationController;
  Status status = Status.visible;

  @override
  void initState() {
    status = Status.visible;
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    computedAttributes = VariableAttributes({}, []);
    extraKeysListened = [];
    onStateChange(currentVariables);
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);
    stateNotifier.addListener(onDiffUpdateEvent);
    connectionNotifier =
        Provider.of<LiveConnectionNotifier>(context, listen: false)
          ..addListener(onReconnect);
    liveView.listenPageAction(handleGlobalAction);
    super.initState();
  }

  @override
  void dispose() {
    stateNotifier.removeListener(onDiffUpdateEvent);
    connectionNotifier.removeListener(onReconnect);
    _animationController?.dispose();
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
    _animationController?.reset();
    _animationController?.value = 0;
    status = Status.visible;
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
      _reloadCalled = false;
      onStateChange(lastLiveDiff);
      if (!_reloadCalled) {
        reloadAttributes([]);
      }
      setState(() {});
    }
  }

  bool isKeyListened(String key) =>
      computedAttributes.keys.contains(key) || extraKeysListened.contains(key);

  void reloadAttributes(List<String> attributes) {
    _reloadCalled = true;
    for (var key in defaultListenedKeys) {
      if (!attributes.contains(key)) {
        attributes.add(key);
      }
    }
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

  @override
  Widget build(BuildContext context) {
    var widget = handleTransitions(render(context));

    if (handleClickState() == HandleClickState.automatic) {
      return handleEvents(widget);
    } else {
      return widget;
    }
  }

  Widget handleTransitions(Widget child) {
    var controller = _animationController;
    if (controller == null) {
      return child;
    }
    return AnimatedBuilder(
        animation: controller,
        builder: (_, __) {
          if (controller.value == 0) {
            return child;
          }
          return ClipRect(
              child: Container(
                  constraints:
                      // 300 since I have no idea how do set fractional height
                      // FractionalSizedBox doesn't work and Align changes the child
                      BoxConstraints(maxHeight: 300 * (1 - controller.value)),
                  child: child));
        });
  }

  void handleAllEvents(List<EventHandler> events) {
    List<FlutterExecAction> actions = [];

    for (var eventName in ['flutter-click', 'phx-click']) {
      actions.addAll(FlutterExec.parse(getAttribute(eventName), eventName));
    }

    for (var action in actions) {
      switch (action.name) {
        case 'phx-click':
          events.add((_) {
            liveView.sendEvent(LiveEvent(
                type: 'phx-click', name: action.value!['name'], value: {}));
          });
        case 'flutter-click':
          if (action.value!['name'] == 'go_back') {
            events.add((BuildContext context) {
              liveView.router.navigatorKey?.currentState?.maybePop();
              liveView.router.notify();
            });
          }
        case 'switchTheme':
          liveView.switchTheme(action.value?['theme'], action.value?['mode']);
        case 'saveCurrentTheme':
          liveView.saveCurrentTheme();
        case 'show':
        case 'hide':
          liveView.dispatchGlobalPageAction(action);
        default:
          print("unknown action $action");
      }
    }
  }

  void handleGlobalAction(FlutterExecAction action) {
    if (!mounted) {
      return;
    }

    switch (action.name) {
      case 'hide':
        var id = ((action.value?['to']) as String?)?.replaceAll('#', '');
        if (id == getAttribute('id')) {
          if (status == Status.hidden) {
            return;
          }
          status = Status.hidden;
          _animationController?.dispose();
          _animationController = AnimationController(
            duration: Duration(milliseconds: action.value?['time'] ?? 200),
            vsync: this,
          )..drive(CurveTween(curve: Curves.ease));
          setState(() {});
          Tween<double>(begin: 0, end: 1).animate(_animationController!);
          _animationController!.forward();
        }
      case 'show':
        var id = ((action.value?['to']) as String?)?.replaceAll('#', '');
        if (id == getAttribute('id')) {
          if (status == Status.visible) {
            return;
          }
          status = Status.visible;
          _animationController?.dispose();
          _animationController = AnimationController(
            duration: Duration(milliseconds: action.value?['time'] ?? 200),
            vsync: this,
          )..drive(CurveTween(curve: Curves.ease));
          setState(() {});
          Tween<double>(begin: 1, end: 0).animate(_animationController!);
          _animationController!.value = 1;
          _animationController!.reverse();
        }
    }
  }

  void executeAllEvents(List<EventHandler> events) {
    for (var event in events) {
      event(context);
    }
  }

  void executeTapEventsManually() {
    List<EventHandler> events = [];

    handleAllEvents(events);
    executeAllEvents(events);
  }

  Widget handleEvents(Widget child) {
    List<EventHandler> events = [];
    handleAllEvents(events);

    if (events.isEmpty) {
      return child;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: () => executeAllEvents(events),
      child: AbsorbPointer(child: child),
    );
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
