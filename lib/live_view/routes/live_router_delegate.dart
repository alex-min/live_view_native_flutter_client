import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/routes/live_custom_page.dart';
import 'package:liveview_flutter/live_view/routes/no_transition_page.dart';
import 'package:liveview_flutter/live_view/ui/components/live_view_body.dart';
import 'package:liveview_flutter/live_view/ui/root_view/internal_view.dart';

class LivePage {
  MaterialPage page;
  List<Widget> widgets;
  bool junk = false;

  LivePage({required this.page, required this.widgets});

  @override
  String toString() => "LivePage(${page.name})";

  bool get notSuitableToGoBack =>
      junk == true || page.name?.startsWith('/') == false;
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
  Future<bool> popRoute() {
    popJunkRoutes();
    // we can't pop the last route because the app will crash
    // there's no way to programatically exit the app on some platforms (iOS)
    // so we just do nothing in this case
    if (pages.length > 1) {
      pages.removeLast();
      var pageName = pages.last.page.name;
      if (pageName != null) {
        view.redirectTo(pageName);
      }
      view.goBackNotifier.notify();
      notifyListeners();
      return Future.value(true);
    }
    return Future.value(true);
  }

  void notify() => notifyListeners();

  void pushPage({required String url, required List<Widget> widget}) {
    history[url] = widget;
    pages.add(_createPage(RouteSettings(name: url), List<Widget>.from(widget)));
    notifyListeners();
  }

  void updatePage({required String url, required List<Widget> widget}) {
    history[url] = widget;
    if (pages.isNotEmpty && pages.last.page.name == url) {
      // we don't remove the page now because the router only keeps track of the number of pages
      // if we remove the junk page directly, it won't trigger a refresh
      // this code is triggered on page refresh
      pages.last.junk = true;
    }
    pages.add(_createPage(RouteSettings(name: url), widget));
    notifyListeners();
  }

  List<Widget>? getWidget(String url) {
    return history[url];
  }

  LivePage _createPage(RouteSettings routeSettings, List<Widget> widgets) {
    var content = Builder(builder: (context) {
      if (widgets.length == 1) {
        return widgets.first;
      }

      Widget? body;
      for (var widget in widgets) {
        if (widget is LiveViewBody) {
          body = widget;
          break;
        } else if (widget is InternalView) {
          body = widget;
          break;
        }
      }
      // TODO: not found page + body error page
      return body ?? const Text('not found');
    });

    return LivePage(
      page: routeSettings.name?.startsWith('/') == true
          ? LiveCustomPage(
              child: content,
              name: routeSettings.name,
              arguments: routeSettings.arguments,
            )
          : NoTransitionPage(
              child: content,
              name: routeSettings.name,
              arguments: routeSettings.arguments),
      widgets: widgets,
    );
  }
}
