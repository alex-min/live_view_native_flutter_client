import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/text_replacement.dart';
import 'package:liveview_flutter/live_view/routes/live_custom_page.dart';
import 'package:liveview_flutter/live_view/routes/no_transition_page.dart';
import 'package:liveview_flutter/live_view/ui/components/live_dynamic_component.dart';
import 'package:liveview_flutter/live_view/ui/components/live_view_body.dart';
import 'package:liveview_flutter/live_view/ui/errors/missing_page_component.dart';
import 'package:liveview_flutter/live_view/ui/node_state.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';
import 'package:xml/xml.dart';

class LivePage {
  MaterialPage page;
  List<Widget> widgets;
  bool junk = false;
  NodeState? rootState;

  LivePage({
    required this.page,
    required this.widgets,
    required this.rootState,
  });

  @override
  String toString() =>
      "LivePage(${page.name})${notSuitableToGoBack ? '[not-suitable-to-go-back]' : ''}";

  bool get notSuitableToGoBack =>
      junk == true || page.name?.startsWith('/') == false;

  bool get containsGlobalNavigationWidgets => widgets.length > 1;
}

class LiveRouterDelegate extends RouterDelegate<List<RouteSettings>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<RouteSettings>> {
  Map<String, List<Widget>> history = {};
  List<LivePage> pages = [];
  LiveView view;

  LiveRouterDelegate(this.view);

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  LivePage? get lastRealPage =>
      pages.where((page) => page.page.name?.startsWith('/') == true).lastOrNull;

  bool _onPopPage(Route route, dynamic result) {
    popJunkRoutes();
    if (!route.didPop(result)) return false;
    popRoute();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: pages.map((p) => p.page).toList(),
      onPopPage: _onPopPage,
    );
  }

  @override
  Future<void> setNewRoutePath(List<RouteSettings> configuration) async {}

  // those are all the routes that we can't go back to using the back button
  // there's multiple kinds of views here
  // - system routes (loading, error, etc)
  // - junk routes which have been refreshed and are outdated
  // doing so when we go back is safe because no animation will be destroyed by that
  void popJunkRoutes() {
    pages.removeWhere((p) => p.notSuitableToGoBack);
  }

  @override
  Future<bool> popRoute() async {
    popJunkRoutes();
    // we can't pop the last route because the app will crash
    // there's no way to programatically exit the app on some platforms (iOS)
    // so we just do nothing in this case
    if (pages.length > 1) {
      pages.removeLast();
      var pageName = pages.last.page.name;
      if (pageName != null) {
        await view.execHrefClick(pageName);
      }
      view.goBackNotifier.notify();
      notifyListeners();
      return true;
    }
    return true;
  }

  void notify() => notifyListeners();

  void pushPage({
    required String url,
    required List<Widget> widget,
    required NodeState? rootState,
  }) {
    history[url] = widget;
    pages.add(
      _createPage(
        RouteSettings(name: url),
        List<Widget>.from(widget),
        rootState,
      ),
    );
    notifyListeners();
  }

  void updatePage({
    required String url,
    required List<Widget> widget,
    required NodeState? rootState,
  }) {
    history[url] = widget;
    var pageIndex = pages.length - 1;
    while (pageIndex >= 0 &&
        (pages.elementAtOrNull(pageIndex)?.page.name == url ||
            pages.elementAtOrNull(pageIndex)?.page.name == 'loading;$url')) {
      // we don't remove the page now because the router only keeps track of the number of pages
      // if we remove the junk page directly, it won't trigger a refresh
      // this code is triggered on page refresh
      pages.elementAtOrNull(pageIndex)!.junk = true;
      pageIndex--;
    }
    pages.add(_createPage(RouteSettings(name: url), widget, rootState));
    notifyListeners();
  }

  List<Widget>? getWidget(String url) {
    return history[url];
  }

  LivePage _createPage(
    RouteSettings routeSettings,
    List<Widget> widgets,
    NodeState? rootState,
  ) {
    var content = Builder(
      builder: (context) {
        if (widgets.length == 1) {
          return widgets.first;
        }

        // Root layout nodes (csrf-token, meta, iframe) are rendered as no-op
        // SizedBoxes. Ignore them when looking for the page body so that a
        // single root widget such as <Scaffold> can be used as the page.
        var meaningfulWidgets =
            widgets.where((widget) {
              if (widget is SizedBox) {
                return widget.width != 0 ||
                    widget.height != 0 ||
                    widget.child != null;
              }
              return true;
            }).toList();

        Widget? body;
        for (var widget in meaningfulWidgets) {
          if (widget is LiveViewBody) {
            body = widget;
            break;
          } else if (widget is InternalView) {
            body = widget;
            break;
          }
        }

        // Allow a single meaningful widget that contains a <viewBody> somewhere
        // in its subtree to be the page. This supports templates that wrap the
        // whole view in a <Scaffold> instead of placing <viewBody> at the root.
        if (body == null &&
            meaningfulWidgets.length == 1 &&
            _containsViewBody(rootState)) {
          return meaningfulWidgets.first;
        }

        // TODO: not found page + body error page
        return body ??
            MissingPageComponent(
              url: routeSettings.name ?? '(url is null)',
              html: rootState?.node.outerXml ?? '',
            );
      },
    );

    return LivePage(
      page:
          routeSettings.name?.startsWith('/') == true
              ? LiveCustomPage(
                child: content,
                name: routeSettings.name,
                arguments: routeSettings.arguments,
              )
              : NoTransitionPage(
                child: content,
                name: routeSettings.name,
                arguments: routeSettings.arguments,
              ),
      widgets: _expandDynamicComponents(widgets),
      rootState: rootState,
    );
  }

  bool _containsViewBody(NodeState? rootState) {
    if (rootState == null) return false;
    return rootState.node.findAllElements('viewBody').isNotEmpty;
  }

  /// Expands [LiveDynamicComponent] widgets so root-level global navigation
  /// widgets (AppBar, Drawer, etc.) rendered inside dynamic components can be
  /// discovered by [RootScaffold]. The expanded widgets are only used for
  /// extraction; the actual page content is built separately.
  List<Widget> _expandDynamicComponents(List<Widget> widgets) {
    List<Widget> expanded = [];
    for (var widget in widgets) {
      expanded.add(widget);
      if (widget is LiveDynamicComponent) {
        expanded.addAll(_extractDynamicComponentChildren(widget));
      }
    }
    return expanded;
  }

  List<Widget> _extractDynamicComponentChildren(
    LiveDynamicComponent component,
  ) {
    var state = component.state;
    List<Widget> result = [];

    // Direct loop variable (e.g. <For> components)
    if (state.variables.containsKey('d')) {
      for (var i = 0; i < state.variables['d'].length; i++) {
        var newState = List<String>.from(state.nestedState);
        newState.add(i.toString());
        result.addAll(
          state.parser
              .parseHtml(
                List<String>.from(state.variables['s']),
                state.variables[i.toString()],
                newState,
              )
              .$1,
        );
      }
      return result;
    }

    // Nested rendered structures (e.g. conditional AppBar)
    var dynamicKeys = extractDynamicKeys(state.node.toString());
    for (var elementKey in dynamicKeys) {
      var currentVariables = state.variables[elementKey.key];
      if (currentVariables is! Map) continue;

      if (currentVariables.containsKey('d')) {
        for (var i = 0; i < currentVariables['d'].length; i++) {
          var newState = List<String>.from(state.nestedState);
          newState.add(elementKey.key);
          newState.add(i.toString());
          result.addAll(
            state.parser
                .parseHtml(
                  List<String>.from(currentVariables['s']),
                  currentVariables[i.toString()],
                  newState,
                )
                .$1,
          );
        }
      } else {
        var newState = List<String>.from(state.nestedState);
        newState.add(elementKey.key);
        var parsed = state.parser.parseHtml(
          List<String>.from(currentVariables['s'] ?? []),
          Map<String, dynamic>.from(currentVariables),
          newState,
        );
        result.addAll(parsed.$1);
      }
    }

    return result;
  }
}
