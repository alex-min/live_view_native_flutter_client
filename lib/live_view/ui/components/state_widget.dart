import 'dart:async';

import 'package:flutter/material.dart';
import 'package:html_unescape/html_unescape.dart';
import 'package:liveview_flutter/exec/flutter_exec.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/reactive/live_connection_notifier.dart';
import 'package:liveview_flutter/live_view/reactive/state_notifier.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_parser.dart';
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
  late List<String> extraKeysListened;
  var defaultListenedKeys = ['phx-click', 'flutter-click', 'id', 'live-patch'];
  AnimationController? _animationController;
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
    reloadPredefinedAttributes();
    stateNotifier = Provider.of<StateNotifier>(context, listen: false);
    stateNotifier.addListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.addListener(onWipeState);
    widget.state.liveView.goBackNotifier.addListener(onGoBack);
    _eventSubscription = liveView.eventHub.on('globalAction', (data) {
      handleGlobalAction(data);
    });
    super.initState();
  }

  @override
  void dispose() {
    stateNotifier.removeListener(onDiffUpdateEvent);
    widget.state.liveView.connectionNotifier.removeListener(onWipeState);
    widget.state.liveView.goBackNotifier.removeListener(onGoBack);
    _animationController?.dispose();
    _eventSubscription.cancel();
    super.dispose();
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

  void onDiffUpdateEvent() {
    if (!mounted) {
      return;
    }
    var lastLiveDiff = stateNotifier.getNestedDiff(widget.state.nestedState);
    if (lastLiveDiff.keys.any((key) => isKeyListened(key))) {
      currentVariables.addAll(lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes();
      setState(() {});
    }
  }

  bool isKeyListened(String key) =>
      computedAttributes.keys.contains(key) || extraKeysListened.contains(key);

  void reloadPredefinedAttributes() {
    var attrs = getVariableAttributes(
        widget.state.node, defaultListenedKeys, currentVariables);
    computedAttributes.merge(attrs);
  }

  void reloadAttributes(List<String> attributes) {
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
      var attribute = computedAttributes.attributes[name];
      if (attribute == null) {
        return null;
      }
      return HtmlUnescape().convert(attribute);
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
        return LiveViewUiParser.traverse(state.copyWith(node: children[0]))
            .first;
      default:
        return Column(children: multipleChildren(state: state));
    }
  }

  List<Widget> multipleChildren({NodeState? state}) {
    state ??= widget.state;
    return state.node.nonEmptyChildren.map((child) {
      return LiveViewUiParser.traverse(state!.copyWith(node: child)).first;
    }).toList();
  }

  List<LiveStateWidget> extractChildren<Type extends LiveStateWidget>(
      List<Widget> children) {
    List<LiveStateWidget> ret = [];
    var refType = (Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase());
    for (var child in children) {
      if (child is Type) {
        ret.add(child);
      }
      if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        ret.add(child);
      }
    }
    children.removeWhere((e) => ret.contains(e));
    return ret;
  }

  LiveStateWidget? extractChild<Type extends Widget>(List<Widget> children) {
    LiveStateWidget? ret;
    var refType = (Type.toString()
        .replaceAll('Live', '')
        .replaceAll('Attribute', '')
        .toLowerCase());
    for (var child in children) {
      if (child is Type) {
        ret = child as LiveStateWidget;
      }
      if (child is LiveStateWidget &&
          child.state.node.getAttribute('as') == refType) {
        ret = child;
      }
    }
    children.removeWhere((e) => e == ret);

    return ret;
  }

  Type? extractWidgetChild<Type extends Widget>(List<Widget> children) {
    Type? ret;
    for (var child in children) {
      if (child is Type) {
        ret = child;
      }
    }
    children.removeWhere((e) => e == ret);

    return ret;
  }

  void executeDirty() {
    if (_dirty) {
      _dirty = false;
      status = Status.visible;
      computedAttributes = VariableAttributes({}, []);
      currentVariables = Map.from(widget.state.variables);
      _animationController?.dispose();
      _animationController = null;
      onStateChange(currentVariables);
      reloadPredefinedAttributes();
    }
  }

  @override
  Widget build(BuildContext context) {
    executeDirty();
    var child = handleTransitions(render(context));

    if (handleClickState() == HandleClickState.automatic) {
      return handleEvents(child);
    } else {
      return child;
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
          if (controller.value == 1) {
            return const SizedBox.shrink();
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

  void handleAllEvents(List<EventHandler> events,
      {Map<String, dynamic>? fromAttributes}) {
    List<FlutterExecAction> actions = [];

    for (var eventName in ['flutter-click', 'phx-click', 'live-patch']) {
      if (fromAttributes != null) {
        if (fromAttributes[eventName] != null) {
          actions
              .addAll(FlutterExec.parse(fromAttributes[eventName], eventName));
        }
      } else {
        actions.addAll(FlutterExec.parse(getAttribute(eventName), eventName));
      }
    }

    for (var action in actions) {
      switch (action.name) {
        case 'live-patch':
          events.add((_) {
            var url = action.value!['name'];
            if (url != null) {
              liveView.router.pushPage(
                  url: 'loading;$url', widget: liveView.loadingWidget());
              liveView.redirectTo(url);
            }
          });
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
          if (action.value?['to'] != null) {
            liveView.eventHub.fire('globalAction', action);
          } else {
            show(action);
          }
        case 'hide':
          if (action.value?['to'] != null) {
            liveView.eventHub.fire('globalAction', action);
          } else {
            hide(action);
          }
        default:
          print("unknown action $action");
      }
    }
  }

  void hide(FlutterExecAction action) {
    if (status == Status.hidden || !mounted) {
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

  void show(FlutterExecAction action) {
    if (status == Status.visible || !mounted) {
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

  void handleGlobalAction(FlutterExecAction action) {
    if (!mounted) {
      return;
    }

    switch (action.name) {
      case 'hide':
        var id = ((action.value?['to']) as String?)?.replaceAll('#', '');
        if (id == null) {
          return;
        }
        if (id == getAttribute('id')) {
          hide(action);
        }
      case 'show':
        var id = ((action.value?['to']) as String?)?.replaceAll('#', '');
        if (id == null) {
          return;
        }
        if (id == getAttribute('id')) {
          show(action);
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

    handleAllEvents(events, fromAttributes: fromAttributes);
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

  // attributes
  double? doubleAttribute(String attribute) =>
      getDouble(getAttribute(attribute));
  int? intAttribute(String attribute) => getInt(getAttribute(attribute));
  Color? colorAttribute(String attribute) =>
      getColor(context, getAttribute(attribute));
  bool? booleanAttribute(String attribute) =>
      getBoolean(getAttribute(attribute));
  Decoration? decorationAttribute(String attribute) =>
      getDecoration(context, getAttribute(attribute));
  EdgeInsetsGeometry? edgeInsetsAttribute(String attribute) =>
      getMarginOrPadding(getAttribute(attribute));
  Icon getIconAttribute(String attribute) =>
      Icon(getIcon(getAttribute('attribute')));
}
