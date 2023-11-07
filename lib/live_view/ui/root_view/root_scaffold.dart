import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/floating_action_button_location.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/computed_attributes.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/live_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_end_drawer.dart';
import 'package:liveview_flutter/live_view/ui/components/live_floating_action_button.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_footer_button.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/loading/reload_widget.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_bottom_navigation_bar.dart';
import 'package:throttled/throttled.dart';

class ShowBottomSheetNotification extends Notification {}

class RootScaffold extends StatefulWidget {
  final LiveView view;
  const RootScaffold({super.key, required this.view});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> with ComputedAttributes {
  List<Widget> children = [];
  bool isLiveReloading = false;
  LiveNavigationRail? railBar;
  LiveDrawer? drawer;
  LiveEndDrawer? endDrawer;
  LiveFloatingActionButton? floatingActionButton;
  FloatingActionButtonLocation? floatingActionButtonLocation;
  List<LiveStateWidget> persistentButtons = [];
  final key = GlobalKey<ScaffoldState>();

  NodeState? rootNode;

  @override
  void initState() {
    widget.view.eventHub.on('live-reload:start', (_) => setState(() {}));
    widget.view.eventHub.on('live-reload:end', (_) => setState(() {}));
    widget.view.router.addListener(routeChange);
    widget.view.changeNotifier.addListener(onDiffUpdateEvent);
    onStateChange(currentVariables);
    super.initState();
  }

  void onDiffUpdateEvent() {
    if (!mounted) {
      return;
    }
    var currentRoot = widget.view.router.pages.last.rootState;
    if (currentRoot == null) {
      return;
    }
    rootNode = currentRoot;
    var lastLiveDiff =
        widget.view.changeNotifier.getNestedDiff(currentRoot.nestedState);
    if (lastLiveDiff.keys.any((key) => isKeyListened(key))) {
      currentVariables.addAll(lastLiveDiff);
      onStateChange(lastLiveDiff);
      reloadPredefinedAttributes(currentRoot.node);
      setState(() {});
    }
  }

  void onStateChange(Map<String, dynamic> diff) {
    if (rootNode == null) {
      return;
    }
    reloadAttributes(rootNode!.node, []);
  }

  @override
  void dispose() {
    widget.view.changeNotifier.removeListener(onDiffUpdateEvent);
    widget.view.router.removeListener(routeChange);
    super.dispose();
  }

  void routeChange() {
    setState(() {
      computedAttributes = VariableAttributes({}, []);
      rootNode = widget.view.router.pages.last.rootState;
    });
  }

  Widget mapRailBar(Widget child) {
    if (railBar == null) {
      return child;
    }
    return Row(children: [railBar!, Expanded(child: child)]);
  }

  void bindFloatingActionButtonLocation() {
    rootNode = widget.view.router.pages.last.rootState;
    if (rootNode != null) {
      var viewBody = childrenNodesOf(rootNode!.node, 'viewBody').firstOrNull;
      if (viewBody != null) {
        var attributes = bindChildVariableAttributes(
            viewBody, ['floatingActionButtonLocation'], rootNode!.variables);
        var location = getFloatingActionButtonLocation(
            attributes['floatingActionButtonLocation']);
        if (location != null) {
          floatingActionButtonLocation = location;
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bindFloatingActionButtonLocation();

    if (widget.view.router.pages.last.containsGlobalNavigationWidgets) {
      var widgets = List<Widget>.from(widget.view.router.pages.last.widgets);

      railBar = StateChild.extractWidgetChild<LiveNavigationRail>(widgets);
      drawer = StateChild.extractWidgetChild<LiveDrawer>(widgets);
      endDrawer = StateChild.extractWidgetChild<LiveEndDrawer>(widgets);
      floatingActionButton =
          StateChild.extractWidgetChild<LiveFloatingActionButton>(widgets);
      persistentButtons =
          StateChild.extractChildren<LivePersistentFooterButton>(widgets);
    } else {
      railBar = null;
      drawer = null;
      floatingActionButton = null;
      persistentButtons = [];
    }

    var child = SafeArea(
        child: Router(
      routerDelegate: widget.view.router,
      backButtonDispatcher: RootBackButtonDispatcher(),
    ));
    var view = Scaffold(
        key: key,
        drawer: drawer,
        endDrawer: endDrawer,
        appBar: RootAppBar(view: widget.view),
        body: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              if (widget.view.throttleSpammyCalls) {
                throttle('window_resize',
                    () => widget.view.eventHub.fire('phx:window:resize'),
                    cooldown: const Duration(milliseconds: 50));
              } else {
                widget.view.eventHub.fire('phx:window:resize');
              }
              return true;
            },
            child: NotificationListener<ShowBottomSheetNotification>(
                onNotification: (_) {
                  var widgets =
                      List<Widget>.from(widget.view.router.pages.last.widgets);
                  var bottomSheet =
                      StateChild.extractWidgetChild<LiveBottomSheet>(widgets);
                  if (bottomSheet == null) {
                    debugPrint('no bottomsheet to show');
                    return true;
                  }

                  key.currentState!.showBottomSheet((context) => bottomSheet);
                  return true;
                },
                child: mapRailBar(SizeChangedLayoutNotifier(
                    child: widget.view.isLiveReloading
                        ? Stack(children: [child, const ReloadWidget()])
                        : child)))),
        bottomNavigationBar: RootBottomNavigationBar(view: widget.view),
        floatingActionButtonLocation: floatingActionButtonLocation,
        floatingActionButton: floatingActionButton,
        persistentFooterButtons:
            persistentButtons.isEmpty ? null : persistentButtons);
    return view;
  }
}
