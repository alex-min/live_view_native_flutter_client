import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/state/attribute_helpers.dart';
import 'package:liveview_flutter/live_view/state/computed_attributes.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:provider/provider.dart';
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
  /// What is notifying the widget of changes
  /// When the page received a diff, this is going to be notified through the stateNotifier
  late StateNotifier stateNotifier;

  /// Animation used for hiding or showing the widget (in milliseconds)
  int? animationDuration;
  Status status = Status.visible;
  late StreamSubscription _eventSubscription;

  /// Dirty flag to indicate that the state needs wiping.
  /// The state isn't wiped instantly due to some side effects when switching views.
  /// It would make the view appear janky when we switch from one page to the other
  /// The state is wiped on the next rerender.
  bool _dirty = false;

  @override
  void initState() {
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);

    status = Status.visible;
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    if (stateNotifier.getDiff().isNotEmpty) {
      var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);
      currentVariables.addAll(lastLiveDiff);
      reloadPredefinedAttributes(node);
    }
    computedAttributes = VariableAttributes({}, []);
    extraKeysListened = [];
    onStateChange(currentVariables);
    onFormInitialize();
    reloadPredefinedAttributes(node);
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

  /// Executes all the onload events registred on the widget in the xml
  void onLoad() {
    List<EventHandler> onLoadEvents = [];

    gatherAllEvents(['phx-onload', 'phx-responsive'], onLoadEvents);
    executeAllEvents(onLoadEvents);
  }

  /// We are wiping the state when going back.
  void onGoBack() {
    _dirty = true;
    executeDirty();
    if (mounted) {
      setState(() {});
    }
  }

  /// called on page change
  void onWipeState() {
    _dirty = true;

    if (!mounted) {
      return;
    }
  }

  /// Called after a diff event from the server on the page
  /// Widgets have to override this method.
  ///
  /// Usually widgets call a method ```reloadAttribute``` this way:
  /// ```
  /// reloadAttributes(node, ['my-attribute1', 'my-attribute2']);
  /// ```
  /// Since this is called on every diff event from the server and before the widget is refreshed.
  void onStateChange(Map<String, dynamic> diff);

  /// Called when the form has to be reinitialized.
  /// Mainly called on page changes.
  ///
  /// Widgets inheriting from this widget can override this method if needed to execute some code when the form initialize.
  /// This can be used to reset some values for example.
  void onFormInitialize() {}

  void onDiffUpdateEvent() {
    if (!mounted) {
      return;
    }
    if (_handleDiff()) {
      setState(() {});
    }
  }

  bool _handleDiff() {
    var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);

    if (lastLiveDiff.keys.any((key) => isKeyListened(ElementKey(key)))) {
      currentVariables.addAll(lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes(node);
      return true;
    }
    return false;
  }

  // a shorthand to get the current xml node & state associated
  XmlNode get node => widget.state.node;

  Widget singleChild({NodeState? state}) =>
      StateChild.singleChild(state ?? widget.state);

  List<Widget> multipleChildren({NodeState? state}) =>
      StateChild.multipleChildren(state ?? widget.state);

  /// This is wiping any state the widget holds
  /// Called after changing pages
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
    }

    return handleBeforeEachRenderEvents(child);
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
          ? SizedBox.shrink(key: Key("${node.hashCode}-invisible"))
          : child,
    );
  }

  void gatherAllEvents(
    List<String> attributes,
    List<EventHandler> events, {
    Map<String, dynamic>? fromAttributes,
  }) {
    convertAttributesToExecs(
      attributes,
      events,
      fromAttributes: fromAttributes,
    ).forEach((e) => events.add((c) => e.conditionalHandler(c, this)));
  }

  void gatherAllTapEvents(
    List<EventHandler> events, {
    Map<String, dynamic>? fromAttributes,
  }) {
    return gatherAllEvents(
      LiveViewExecRegistry.instance.execsByTrigger(LiveViewExecTrigger.onTap),
      events,
      fromAttributes: fromAttributes,
    );
  }

  List<Exec> convertAttributesToExecs(
    List<String> attributes,
    List<EventHandler> events, {
    Map<String, dynamic>? fromAttributes,
  }) {
    List<Exec> actions = [];

    for (var eventName in attributes) {
      if (fromAttributes != null) {
        if (fromAttributes[eventName] != null) {
          actions.addAll(FlutterExec.parse(
            fromAttributes[eventName],
            eventName,
            fromAttributes,
          ));
        }
      } else if (getAttribute(eventName) != null) {
        actions.addAll(FlutterExec.parse(
          getAttribute(eventName),
          eventName,
          computedAttributes.attributes,
        ));
      }
    }
    return actions;
  }

  /// hiding the current widget with an animation
  /// Does nothing if the widget is already hidden or not on the page
  void hide(ExecHideAction action) {
    if (status == Status.hidden ||
        !mounted ||
        !widget.state.isOnTheCurrentPage) {
      return;
    }
    status = Status.hidden;
    animationDuration = action.timeInMilliseconds ?? 0;
    setState(() {});
  }

  /// shows back the current widget with an animation
  /// Does nothing if the widget is already fully visible or not on the page
  void show(ExecShowAction action) {
    if (status == Status.visible ||
        !mounted ||
        !widget.state.isOnTheCurrentPage) {
      return;
    }
    status = Status.visible;
    animationDuration = action.timeInMilliseconds ?? 0;
    setState(() {});
  }

  /// You can call hide or show events on a id which is anywhere in the page
  /// To support that, each widget is listening to global events and checks if the id matches the current widget itself.
  /// The ids work exactly as the id attribute in the HTML DOM
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

  /// Executes a list of events which are already built before by another method
  /// Those events can be tap events, navigation events or anything else.
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
    gatherAllEvents(
      ['phx-on-trigger'],
      events,
      fromAttributes: fromAttributes,
    );
    executeAllEvents(events);
  }

  void executeOnTapOutsideEventsManually(
      {Map<String, dynamic>? fromAttributes}) {
    List<EventHandler> events = [];

    reloadPredefinedAttributes(node);
    gatherAllEvents(
      ['phx-click-outside'],
      events,
      fromAttributes: fromAttributes,
    );
    executeAllEvents(events);
  }

  /// Called when the window is being resized
  /// This is used to build responsive navigation
  /// You can do things like this on the server side:
  /// ```xml
  /// <NavigationRail labelType="all" selectedIndex="0"
  ///     phx-responsive={Dart.show()}
  ///     phx-responsive-when="screen-md"> ...
  /// </NavigationRail>
  /// ```
  /// See ```lib/when/when.dart``` for a list of all the breakpoints
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
      ),
    );
  }

  Widget render(BuildContext context);

  /// The client handles phx-click on every widgets
  /// For most widgets like ```<Text>```, you can just wrap it in a ```MouseRegion``` and it will handle the tap event.
  /// This is what ```HandleClickState.automatic``` is for (and the default)
  ///
  /// For other widgets like ```<ElevatedButton>```, taping has a specific meaning.
  /// The widget has to handle the tap events itself and call ```executeTapEventsManually();``` when needed
  /// This is ```HandleClickState.manual``` is for
  HandleClickState handleClickState() {
    return HandleClickState.automatic;
  }

  LiveView get liveView => widget.state.liveView;

  void listenInnerTextKeys() {
    for (var key in extractDynamicKeys(widget.state.node.toString())) {
      addListenedKey(key);
    }
  }

  /// In Flutter, components can accept either a single child or multiple children but not both.
  /// How the client reconciles this is to add a `Column` widget if needed to behave more like HTML.
  /// Raw text elements in the xml payload are transformed into a basic Flutter `Text` widget.
  /// Those two buttons are equivalent:
  ///
  /// ```xml
  /// <ElevatedButton>Click me</ElevatedButton>
  /// <ElevatedButton><Text>Click me</Text></ElevatedButton>
  /// ```
  ///
  /// And those two buttons are exactly rendered the same way as well:
  ///
  /// ```xml
  /// <ElevatedButton>
  ///     <Column>
  ///         <Text>Click</Text>
  ///         <Text> me</Text>
  ///     </Column>
  /// </ElevatedButton>
  ///
  /// <ElevatedButton>
  ///     <Text>Click</Text>
  ///     <Text> me</Text>
  /// </ElevatedButton>
  /// ```
  Widget body(List<Widget> children) {
    return switch (children.length) {
      0 => const SizedBox.shrink(),
      1 => children[0],
      _ => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        )
    };
  }
}
