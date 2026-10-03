import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
import 'package:liveview_flutter/live_view/ui/dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:liveview_flutter/when/when.dart';
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

Map<String, dynamic> mergeVariables(
  Map<String, dynamic> base,
  Map<String, dynamic> overlay,
) {
  var result = Map<String, dynamic>.from(base);
  for (var entry in overlay.entries) {
    var existing = result[entry.key];
    var value = entry.value;
    // A map carrying statics is a complete section replacement (e.g. an
    // if/else or case switching back to a previous branch). Merging it
    // recursively with the previously rendered section would retain stale
    // keys (comprehension rows, prior branch slots) and corrupt the render.
    if (existing is Map && value is Map && !value.containsKey('s')) {
      result[entry.key] = mergeVariables(
        Map<String, dynamic>.from(existing),
        Map<String, dynamic>.from(value),
      );
    } else {
      result[entry.key] = value;
    }
  }
  return result;
}

abstract class StateWidget<T extends LiveStateWidget> extends State<T>
    with TickerProviderStateMixin, AttributeHelpers, ComputedAttributes {
  /// What is notifying the widget of changes
  /// When the page received a diff, this is going to be notified through the stateNotifier
  late StateNotifier stateNotifier;

  /// Animation used for hiding or showing the widget (in milliseconds)
  int? animationDuration;
  Status status = Status.visible;
  StreamSubscription? _globalActionSubscription;
  StreamSubscription? _windowResizeSubscription;

  /// Dirty flag to indicate that the state needs wiping.
  /// The state isn't wiped instantly due to some side effects when switching views.
  /// It would make the view appear janky when we switch from one page to the other
  /// The state is wiped on the next rerender.
  bool _dirty = false;

  /// Whether the initial responsive visibility was already applied for this
  /// widget instance.
  bool _responsiveVisibilityApplied = false;

  @override
  void initState() {
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);

    stateNotifier.addListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.addListener(onWipeState);
    widget.state.liveView.goBackNotifier.addListener(onGoBack);
    _globalActionSubscription = liveView.eventHub.on('globalAction', (data) {
      handleGlobalAction(data);
    });
    _windowResizeSubscription = liveView.eventHub.on('phx:window:resize', (
      data,
    ) {
      onWindowResize();
    });
    if (node.getAttribute('phx-onload') != null ||
        node.getAttribute('phx-responsive') != null) {
      Future.delayed(Duration.zero, () => onLoad());
    }
    if (LiveViewExecRegistry.instance
        .execsByTrigger(LiveViewExecTrigger.onMount)
        .any((attribute) => node.getAttribute(attribute) != null)) {
      // Firing is deferred to the end of the frame (like onLoad) because the
      // handler needs a mounted context. Firing from initState means the exec
      // runs exactly once per element insertion; attribute updates on a kept
      // element and server diffs reuse the same State instance and never
      // re-trigger it. MountExecTracker dedups the subtree re-creations that
      // server diffs cause, which plain element lifecycle cannot distinguish
      // from real insertions.
      SchedulerBinding.instance.addPostFrameCallback((_) {
        executeOnMountEvents();
      });
    }
    super.initState();
  }

  /// Whether [initializeVariables] already ran for this widget instance.
  bool _variablesInitialized = false;

  /// Resolves the attributes for the first build. Runs from
  /// [didChangeDependencies] instead of [initState] so the pending diff can
  /// be validated against the route: looking up [ModalRoute] requires an
  /// active element, which [initState] does not have yet.
  void initializeVariables() {
    if (_variablesInitialized) {
      return;
    }
    _variablesInitialized = true;

    status = Status.visible;
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    if (stateNotifier.getDiff().isNotEmpty && isDiffTarget()) {
      var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);
      currentVariables = mergeVariables(currentVariables, lastLiveDiff);
    }
    // Keep keys registered by subclasses in initState after super.initState
    // (e.g. listenInnerTextKeys): they run before this first initialization.
    computedAttributes = VariableAttributes({}, []);
    onStateChange(currentVariables);
    onFormInitialize();
    reloadPredefinedAttributes(node);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    initializeVariables();
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (identical(oldWidget.state, widget.state)) {
      return;
    }

    status = Status.visible;
    computedAttributes = VariableAttributes({}, []);
    currentVariables = Map<String, dynamic>.from(widget.state.variables);
    extraKeysListened = [];
    onStateChange(currentVariables);
    onFormInitialize();
    reloadPredefinedAttributes(node);
  }

  @override
  void dispose() {
    stateNotifier.removeListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.removeListener(onWipeState);
    widget.state.liveView.goBackNotifier.removeListener(onGoBack);
    _globalActionSubscription?.cancel();
    _windowResizeSubscription?.cancel();
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

  /// Whether server diffs may be applied to this widget. Diffs always
  /// target the page currently joined on the channel; widgets from other
  /// routes (kept mounted in the navigation stack, including an offstage
  /// visit to the same URL) must ignore them.
  bool isDiffTarget() {
    if (!widget.state.isOnTheCurrentPage) {
      return false;
    }
    final page = ModalRoute.settingsOf(context);
    if (page is Page &&
        page.key != liveView.router.pages.lastOrNull?.page.key) {
      return false;
    }
    return true;
  }

  bool _handleDiff() {
    // Diffs from the server always target the page currently joined on the
    // channel. Widgets from previous pages stay mounted in the navigation
    // stack and keep listening; their top-level dynamic keys collide with
    // the current page's keys (both have an empty nestedState), so applying
    // the diff would merge unrelated statics and dynamics together. A prior
    // visit to the same URL must also be excluded by its route identity.
    if (!isDiffTarget()) {
      return false;
    }
    var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);

    if (lastLiveDiff.keys.any((key) => isKeyListened(ElementKey(key)))) {
      currentVariables = mergeVariables(currentVariables, lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes(node);
      return true;
    }
    return false;
  }

  // a shorthand to get the current xml node & state associated
  XmlNode get node => widget.state.node;

  /// Whether this widget belongs to the visible navigation instance.
  ///
  /// URL equality alone is insufficient after navigating away and back to the
  /// same URL because Flutter keeps the previous route mounted offstage.
  bool get isOnCurrentRoute {
    if (!mounted || !widget.state.isOnTheCurrentPage) {
      return false;
    }
    final route = ModalRoute.of(context);
    return route == null || route.isCurrent;
  }

  Widget singleChild({NodeState? state}) =>
      StateChild.singleChild(state ?? widget.state);

  List<Widget> multipleChildren({NodeState? state}) =>
      StateChild.multipleChildren(state ?? widget.state);

  List<Widget>? _flexChildrenCache;
  Object? _flexChildrenNode;
  Map<dynamic, dynamic>? _flexChildrenVariables;

  /// Children parsed for flex parents (Row, Column, Flex): server-side
  /// comprehensions and conditionals resolve to several sibling widgets and
  /// are expanded inline so they participate in the flex layout instead of
  /// being stacked by the dynamic component's internal column.
  ///
  /// The parse result is cached and only recomputed when the subtree's
  /// variables change (a server diff), so unrelated rebuilds keep the
  /// existing widget instances and their state.
  List<Widget> flexChildren() {
    if (_flexChildrenCache != null &&
        identical(_flexChildrenNode, widget.state.node) &&
        identical(_flexChildrenVariables, currentVariables)) {
      return _flexChildrenCache!;
    }
    _flexChildrenNode = widget.state.node;
    _flexChildrenVariables = currentVariables;
    final childState = widget.state.copyWith(
      variables: expandVariables(Map<String, dynamic>.from(currentVariables)),
    );
    _flexChildrenCache = StateChild.flattenDynamics(
      StateChild.multipleChildren(childState),
    );
    return _flexChildrenCache!;
  }

  /// This is wiping any state the widget holds
  /// Called after changing pages
  void executeDirty() {
    if (_dirty) {
      _dirty = false;
      status = Status.visible;
      _responsiveVisibilityApplied = false;
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
    applyInitialResponsiveVisibility();
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

  /// Applies phx-responsive show/hide execs to this widget before its first
  /// paint.
  ///
  /// onLoad() only runs after the first frame, so a widget that a
  /// phx-responsive exec hides used to paint visible and then collapse once
  /// the exec ran, producing a visible relayout on every page open.
  /// Resolving the execs from the XML tree up front lets the widget build
  /// directly in its final visibility state. Execs whose condition does not
  /// match apply their inverse action, mirroring
  /// [ExecVisibilityAction.conditionalHandler].
  void applyInitialResponsiveVisibility() {
    if (_responsiveVisibilityApplied) return;
    _responsiveVisibilityApplied = true;

    final id = node.getAttribute('id');
    if (id == null && node.getAttribute('phx-responsive') == null) return;

    final hiddenIds = _responsiveHiddenIds(node.root);
    if (id != null && hiddenIds.contains(id) && status == Status.visible) {
      status = Status.hidden;
      animationDuration ??= 0;
    }
  }

  Set<String> _responsiveHiddenIds(XmlNode root) {
    final hidden = <String>{};
    final shown = <String>{};
    for (final element in root.descendants.whereType<XmlElement>()) {
      final responsive = element.getAttribute('phx-responsive');
      if (responsive == null) continue;
      final conditions = When(
        conditions: element.getAttribute('phx-responsive-when') ?? '',
      );
      final matches = conditions.execute(context);
      for (final exec in FlutterExec.parse(
        responsive,
        'phx-responsive',
        null,
      )) {
        if (exec is! ExecVisibilityAction || exec.to == null) continue;
        final hides = (exec is ExecHideAction) == matches;
        if (hides) {
          hidden.add(exec.to!);
          shown.remove(exec.to!);
        } else {
          shown.add(exec.to!);
          hidden.remove(exec.to!);
        }
      }
    }
    hidden.removeWhere(shown.contains);
    return hidden;
  }

  Widget handleTransitions(Widget child) {
    if (animationDuration == null) {
      return child;
    }

    return AnimatedSwitcher(
      duration: Duration(milliseconds: animationDuration ?? 0),
      child:
          status == Status.hidden
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
          actions.addAll(
            FlutterExec.parse(
              fromAttributes[eventName],
              eventName,
              fromAttributes,
            ),
          );
        }
      } else if (getAttribute(eventName) != null) {
        actions.addAll(
          FlutterExec.parse(
            getAttribute(eventName),
            eventName,
            computedAttributes.attributes,
          ),
        );
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
  void handleGlobalAction(Exec action) {
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

  /// Executes the execs carried by attributes registered with the
  /// [LiveViewExecTrigger.onMount] trigger (e.g. `phx-on-mount`). Called once
  /// when the widget is inserted into the tree, never on rebuilds.
  ///
  /// Firing is gated by [MountExecTracker]: because diffs re-create widget
  /// subtrees, element lifecycle alone can't tell a kept element from a
  /// re-inserted one, so the tracker dedups on (element position, resolved
  /// payload) and only lets a payload through again when a diff re-introduced
  /// the statics carrying it.
  void executeOnMountEvents() {
    if (!mounted) {
      return;
    }

    reloadPredefinedAttributes(node);

    final mountAttributes = LiveViewExecRegistry.instance.execsByTrigger(
      LiveViewExecTrigger.onMount,
    );
    final eligible =
        mountAttributes.where((attribute) {
          final value = getAttribute(attribute);
          return value != null &&
              liveView.mountTracker.shouldFire(
                nestedState: widget.state.nestedState,
                childIndex: _mountChildIndex(),
                attribute: attribute,
                resolvedValue: value,
              );
        }).toList();

    if (eligible.isEmpty) {
      return;
    }

    List<EventHandler> events = [];
    gatherAllEvents(eligible, events);
    executeAllEvents(events);
  }

  /// Position of this element among its parent's non-empty children, used to
  /// distinguish siblings carrying identical mount payloads.
  int _mountChildIndex() {
    final parent = node.parent;
    if (parent == null) {
      return 0;
    }
    final children = parent.nonEmptyChildren;
    for (var i = 0; i < children.length; i++) {
      if (identical(children[i], node)) {
        return i;
      }
    }
    return 0;
  }

  void executeOnTriggerEventsManually({Map<String, dynamic>? fromAttributes}) {
    List<EventHandler> events = [];

    reloadPredefinedAttributes(node);
    gatherAllEvents(['phx-on-trigger'], events, fromAttributes: fromAttributes);
    executeAllEvents(events);
  }

  void executeOnTapOutsideEventsManually({
    Map<String, dynamic>? fromAttributes,
  }) {
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

    gatherAllEvents([
      'phx-window-resize',
      'phx-responsive',
    ], windowResizeEvents);
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
      // No AbsorbPointer: child buttons (dropdowns, icon buttons) must stay
      // tappable. The gesture arena already lets the deepest recognizer win,
      // so taps on non-interactive areas still reach this detector while
      // taps on child controls are handled by them.
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => executeAllEvents(tapEvents),
        child: child,
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
      _ => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    };
  }
}
