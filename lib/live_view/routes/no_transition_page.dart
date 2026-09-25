import 'package:flutter/material.dart';

class NoTransitionPage extends MaterialPage {
  const NoTransitionPage({
    required super.child,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  @override
  Route createRoute(BuildContext context) {
    late PageRouteBuilder<dynamic> route;
    route = PageRouteBuilder<dynamic>(
      settings: this,
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return (route.settings as NoTransitionPage).child;
      },
    );
    return route;
  }
}
