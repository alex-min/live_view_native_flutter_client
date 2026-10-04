import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/floating_action_button_location.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/state/computed_attributes.dart';
import 'package:liveview_flutter/live_view/state/element_key.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
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
import 'package:liveview_flutter/live_view/ui/root_view/persistent_chrome_layer.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_persistent_top_bar.dart';
import 'package:throttled/throttled.dart';
import 'package:xml/xml.dart';

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
  bool hasBottomNavigationBar = false;
  bool hasMobileBottomNavigationBar = false;
  bool hasAppBar = false;
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
    var lastLiveDiff = widget.view.changeNotifier.getNestedDiff(
      currentRoot.nestedState,
    );
    if (lastLiveDiff.keys.any((key) => isKeyListened(ElementKey(key)))) {
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
      // No viewBody yet (e.g. a loading route that hasn't parsed): keep the
      // previous location so the chrome doesn't flicker mid-navigation.
      if (viewBody == null) {
        return;
      }
      var attributes = bindChildVariableAttributes(viewBody, [
        'floatingActionButtonLocation',
      ], rootNode!.variables);
      // A page without the attribute gets the scaffold default; keeping the
      // previous page's location here would misplace the FAB (e.g. the
      // transaction form's centerDockedWithoutBar carried onto pages whose
      // bottom bar is present).
      floatingActionButtonLocation = getFloatingActionButtonLocation(
        attributes['floatingActionButtonLocation'],
      );
    }
  }

  String? getRootAttribute(String name) {
    if (widget.view.router.pages.last.rootState == null) return null;

    var rootNode = widget.view.router.pages.last.rootState!.node;
    var rootElement = rootNode is XmlDocument ? rootNode.rootElement : rootNode;

    var attributes = bindChildVariableAttributes(rootElement, [
      name,
    ], widget.view.router.pages.last.rootState!.variables);

    return attributes[name];
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
      hasAppBar = widgets.any((widget) => widget is LiveAppBar);
      hasBottomNavigationBar = widgets.any(
        (widget) =>
            widget is LiveBottomNavigationBar || widget is LiveBottomAppBar,
      );
      hasMobileBottomNavigationBar = widgets.any(
        (widget) =>
            widget is LiveBottomNavigationBar ||
            (widget is LiveBottomAppBar &&
                widget.state.node
                    .findAllElements('BottomNavigationBar')
                    .isNotEmpty),
      );
    } else {
      railBar = null;
      drawer = null;
      floatingActionButton = null;
      hasAppBar = false;
      hasBottomNavigationBar = false;
      hasMobileBottomNavigationBar = false;
      persistentButtons = [];
    }

    final hasCompactAppBar = widgetsContainCompactAppBar(
      widget.view.router.pages.last.widgets,
    );
    // Compact app bars are the native bottom-tab layout: they intentionally
    // contribute no toolbar or status-bar inset. Keep the route edge-to-edge
    // even during the frame where the root attribute is still catching up to
    // the newly selected tab — or while the previous tab's page is still on
    // top during a cached switch — otherwise SafeArea briefly paints a top
    // strip. The body then pads itself below the status bar (see below).
    var recentPages =
        widget.view.router.pages.length > 1
            ? widget.view.router.pages.sublist(
              widget.view.router.pages.length - 2,
            )
            : widget.view.router.pages;
    var hasRecentCompactAppBar = recentPages.any(
      (page) => widgetsContainCompactAppBar(page.widgets),
    );
    var extendBodyBehindAppBar =
        getBoolean(getRootAttribute('extendBodyBehindAppBar')) ??
        hasRecentCompactAppBar;
    var extendBody = getBoolean(getRootAttribute('extendBody')) ?? false;

    // The bottom navigation bar only appears under the mobile breakpoint;
    // the top bar is hidden with the same condition, like a native app.
    var hideAppBar =
        hasAppBar &&
        (hasCompactAppBar ||
            (hasMobileBottomNavigationBar &&
                MediaQuery.of(context).size.width <
                    LiveBottomNavigationBar.mobileBreakpoint));

    var router = Router(
      routerDelegate: widget.view.router,
      backButtonDispatcher: RootBackButtonDispatcher(),
    );
    // Pages whose app bar is hidden or compact leave the top edge uncovered
    // by chrome. Their body content pads itself below the status bar (see
    // LiveViewBody); the scaffold stays edge-to-edge so ambient backgrounds
    // still paint behind the status bar.
    widget.view.padBodyBelowStatusBar = extendBodyBehindAppBar && hideAppBar;
    var child = extendBodyBehindAppBar ? router : SafeArea(child: router);

    child = Column(
      children: [
        RootPersistentTopBar(view: widget.view),
        Expanded(child: child),
      ],
    );

    child = Stack(children: [child, PersistentChromeLayer(view: widget.view)]);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      key: key,
      drawer: drawer,
      endDrawer: endDrawer,
      primary: getBoolean(getRootAttribute('primary')) ?? true,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      appBar: hasAppBar && !hideAppBar ? RootAppBar(view: widget.view) : null,
      body: NotificationListener<SizeChangedLayoutNotification>(
        onNotification: (_) {
          if (widget.view.throttleSpammyCalls) {
            throttle(
              'window_resize',
              () => widget.view.eventHub.fire('phx:window:resize'),
              cooldown: const Duration(milliseconds: 50),
            );
          } else {
            widget.view.eventHub.fire('phx:window:resize');
          }
          return true;
        },
        child: NotificationListener<ShowBottomSheetNotification>(
          onNotification: (_) {
            var widgets = List<Widget>.from(
              widget.view.router.pages.last.widgets,
            );
            var bottomSheet = StateChild.extractWidgetChild<LiveBottomSheet>(
              widgets,
            );
            if (bottomSheet == null) {
              debugPrint('No bottomsheet to show');
              return true;
            }

            key.currentState!.showBottomSheet((context) => bottomSheet);
            return true;
          },
          child: mapRailBar(
            SizeChangedLayoutNotifier(
              child:
                  widget.view.isLiveReloading
                      ? Stack(children: [child, const ReloadWidget()])
                      : child,
            ),
          ),
        ),
      ),
      bottomNavigationBar:
          hasBottomNavigationBar
              ? RootBottomNavigationBar(view: widget.view)
              : null,
      floatingActionButtonLocation: floatingActionButtonLocation,
      floatingActionButton: floatingActionButton,
      persistentFooterButtons:
          persistentButtons.isEmpty ? null : persistentButtons,
    );
  }

  bool widgetsContainCompactAppBar(List<Widget> widgets) {
    return widgets.whereType<LiveAppBar>().any(
      (appBar) => appBar.preferredSize.height == 0,
    );
  }
}
