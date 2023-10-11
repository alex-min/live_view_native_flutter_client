import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';

class LiveRouterDelegate extends RouterDelegate<List<RouteSettings>>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<List<RouteSettings>> {
  Map<String, Widget> history = {};
  final List<Page<dynamic>> _pages = [];
  LiveView view;

  LiveRouterDelegate(this.view);

  @override
  final navigatorKey = GlobalKey<NavigatorState>();

  bool _onPopPage(Route route, dynamic result) {
    if (!route.didPop(result)) return false;
    popRoute();
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: List.of(_pages),
      onPopPage: _onPopPage,
    );
  }

  @override
  Future<void> setNewRoutePath(List<RouteSettings> configuration) async {}

  @override
  Future<bool> popRoute() {
    if (_pages.length > 1) {
      _pages.removeLast();
      var pageName = _pages.last.name;
      if (pageName != null) {
        view.redirectTo(pageName);
      }
      notifyListeners();
      return Future.value(true);
    }
    // this could be a "confim quitting the app modal"
    return Future.value(true);
  }

  void notify() => notifyListeners();

  void pushPage({required String url, required Widget widget}) {
    history[url] = widget;
    _pages.add(_createPage(RouteSettings(name: url), widget));
    notifyListeners();
  }

  void updatePage({required String url, required Widget widget}) {
    history[url] = widget;
    if (_pages.isNotEmpty &&
        (_pages.last.name == 'loading' || _pages.last.name == url)) {
      _pages.removeLast();
    }
    _pages.add(_createPage(RouteSettings(name: url), widget));
    notifyListeners();
  }

  Widget getWidget(String url) {
    if (history.containsKey(url)) {
      return history[url]!;
    }
    history[url] = Container();
    return history[url]!;
  }

  MaterialPage _createPage(RouteSettings routeSettings, Widget widget) {
    return MaterialPage(
      child: Builder(builder: (context) {
        return history[routeSettings.name] ?? const Text('not found');
      }),
      name: routeSettings.name,
      arguments: routeSettings.arguments,
    );
  }
}
