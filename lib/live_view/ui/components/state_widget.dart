import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/state/attribute_helpers.dart';
import 'package:liveview_flutter/live_view/state/computed_attributes.dart';
import 'package:liveview_flutter/live_view/state/events.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:provider/provider.dart';
import 'package:uuid/rng.dart';
import 'package:xml/xml.dart';

enum Status { visible, hidden }

enum HandleClickState { automatic, manual }

abstract class LiveStateWidget<T extends StatefulWidget>
    extends StatefulWidget {
  final NodeState state;
  const LiveStateWidget({super.key, required this.state});
}

typedef EventHandler = void Function(BuildContext context);

abstract class StateWidget<T extends LiveStateWidget> extends State<T>
    with TickerProviderStateMixin, AttributeHelpers, ComputedAttributes {
  late StateNotifier stateNotifier;
  int? animationDuration;
  Status status = Status.visible;
  late StreamSubscription _eventSubscription;
  bool _dirty = false;

  @override
  void initState() {
    status = Status.visible;
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    computedAttributes = VariableAttributes({}, []);
    extraKeysListened = [];
    onStateChange(currentVariables);
    onFormInitialize();
    reloadPredefinedAttributes(node);
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);
    stateNotifier.addListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.addListener(onWipeState);
    widget.state.liveView.goBackNotifier.addListener(onGoBack);
    _eventSubscription = liveView.eventHub.on('globalAction', (data) {
      handleGlobalAction(data);
    });
    _eventSubscription = liveView.eventHub.on('phx:window:resize', (data) {
      onWindowResize();
    });
    if (node.getAttribute('phx-onload') != null ||
        node.getAttribute('phx-responsive') != null) {
      Future.delayed(Duration.zero, () => onLoad());
    }
    super.initState();
  }

  @override
  void dispose() {
    stateNotifier.removeListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.removeListener(onWipeState);
    widget.state.liveView.goBackNotifier.removeListener(onGoBack);
    _eventSubscription.cancel();
    super.dispose();
  }

  void onLoad() {
    List<EventHandler> onLoadEvents = [];

    gatherAllEvents(['phx-onload', 'phx-responsive'], onLoadEvents);
    executeAllEvents(onLoadEvents);
  }

  void onGoBack() {
    _dirty = true;
    executeDirty();
    if (mounted) {
      setState(() {});
    }
  }

  void onWipeState() {
    _dirty = true;

    if (!mounted) {
      return;
    }
  }

  void onStateChange(Map<String, dynamic> diff);

  void onFormInitialize() {}

  void onDiffUpdateEvent() {
    if (!mounted) {
      return;
    }
    var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);
    if (lastLiveDiff.keys.any((key) => isKeyListened(key))) {
      currentVariables.addAll(lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes(node);
      setState(() {});
    }
  }

  XmlNode get node => widget.state.node;

  Widget singleChild({NodeState? state}) =>
      StateChild.singleChild(state ?? widget.state);

  List<Widget> multipleChildren({NodeState? state}) =>
      StateChild.multipleChildren(state ?? widget.state);

  void executeDirty() {
    if (_dirty) {
      _dirty = false;
      status = Status.visible;
      computedAttributes = VariableAttributes({}, []);
      currentVariables = Map.from(widget.state.variables);
      onStateChange(currentVariables);
      onFormInitialize();
      reloadPredefinedAttributes(node);
      onLoad();
    }
  }

  @override
  Widget build(BuildContext context) {
    executeDirty();
    var child = handleTransitions(render(context));
    child = handleMarginPadding(child);

    if (handleClickState() == HandleClickState.automatic) {
      return handleBeforeEachRenderEvents(handleTapEvents(child));
    } else {
      return handleBeforeEachRenderEvents(child);
    }
  }

  Widget handleMarginPadding(Widget child) {
    return child;
  }

  Widget handleTransitions(Widget child) {
    if (animationDuration == null) {
      return child;
    }

    return AnimatedSwitcher(
        duration: Duration(milliseconds: animationDuration ?? 0),
        child: status == Status.hidden
            ? SizedBox.shrink(
                key: Key("${node.hashCode}-invisible"),
              )
            : child);
  }

  void gatherAllEvents(List<String> attributes, List<EventHandler> events,
      {Map<String, dynamic>? fromAttributes}) {
    var actions = convertAttributesToExecs(attributes, events,
        fromAttributes: fromAttributes);
    StateEvents.convertExecsToEventHandler(context, events, actions, this);
  }

  void gatherAllTapEvents(List<EventHandler> events,
          {Map<String, dynamic>? fromAttributes}) =>
      gatherAllEvents(
          ['phx-click', 'live-patch', 'phx-href', 'phx-href-modal'], events,
          fromAttributes: fromAttributes);

  List<Exec> convertAttributesToExecs(
      List<String> attributes, List<EventHandler> events,
      {Map<String, dynamic>? fromAttributes}) {
    List<Exec> actions = [];

    for (var eventName in attributes) {
      if (fromAttributes != null) {
        if (fromAttributes[eventName] != null) {
          actions.addAll(FlutterExec.parse(
              fromAttributes[eventName], eventName, fromAttributes));
        }
      } else if (getAttribute(eventName) != null) {
        actions.addAll(FlutterExec.parse(
            getAttribute(eventName), eventName, computedAttributes.attributes));
      }
    }
    return actions;
  }

  void hide(ExecHideAction action) {
    if (status == Status.hidden ||
        !mounted ||
        !widget.state.isOnTheCurrentPage) {
      return;
    }
    status = Status.hidden;
    animationDuration = action.timeInMilliseconds ?? 0;
  }

  void show(ExecShowAction action) {
    if (status == Status.visible ||
        !mounted ||
        !widget.state.isOnTheCurrentPage) {
      return;
    }
    status = Status.visible;
    animationDuration = action.timeInMilliseconds ?? 0;
  }

  void handleGlobalAction(FlutterExecAction action) {
    if (!mounted) {
      return;
    }

    switch (action) {
      case final ExecHideAction event:
        if (event.to == null) {
          return;
        }
        if (event.to == getAttribute('id')) {
          hide(event);
        }
      case final ExecShowAction event:
        if (event.to == null) {
          return;
        }
        if (event.to == getAttribute('id')) {
          show(event);
        }
    }
  }

  void executeAllEvents(List<EventHandler> events) {
    for (var event in events) {
      event(context);
    }
  }

  void executeTapEventsManually({Map<String, dynamic>? fromAttributes}) {
    List<EventHandler> events = [];

    reloadPredefinedAttributes(node);
    gatherAllTapEvents(events, fromAttributes: fromAttributes);
    executeAllEvents(events);
  }

  void executeOnTriggerEventsManually({Map<String, dynamic>? fromAttributes}) {
    List<EventHandler> events = [];

    reloadPredefinedAttributes(node);
    gatherAllEvents(['phx-on-trigger'], events, fromAttributes: fromAttributes);
    executeAllEvents(events);
  }

  void executeOnTapOutsideEventsManually(
      {Map<String, dynamic>? fromAttributes}) {
    List<EventHandler> events = [];

    reloadPredefinedAttributes(node);
    gatherAllEvents(['phx-click-outside'], events,
        fromAttributes: fromAttributes);
    executeAllEvents(events);
  }

  void onWindowResize() {
    if (!widget.state.isOnTheCurrentPage) {
      return;
    }
    List<EventHandler> windowResizeEvents = [];

    gatherAllEvents(
        ['phx-window-resize', 'phx-responsive'], windowResizeEvents);
    executeAllEvents(windowResizeEvents);
  }

  Widget handleBeforeEachRenderEvents(Widget child) {
    List<EventHandler> eachRenderEvent = [];

    if (widget.state.isOnTheCurrentPage) {
      gatherAllEvents(['phx-before-each-render'], eachRenderEvent);
      executeAllEvents(eachRenderEvent);
    }
    return child;
  }

  Widget handleTapEvents(Widget child) {
    List<EventHandler> tapEvents = [];

    gatherAllTapEvents(tapEvents);

    if (tapEvents.isEmpty) {
      return child;
    }

    return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: () => executeAllEvents(tapEvents),
          child: AbsorbPointer(child: child),
        ));
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
