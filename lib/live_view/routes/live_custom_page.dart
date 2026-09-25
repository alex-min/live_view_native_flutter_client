import 'package:flutter/material.dart';

class LiveCustomPage extends MaterialPage {
  final bool noTransition;

  const LiveCustomPage({
    required super.child,
    this.noTransition = false,
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
      transitionDuration:
          noTransition ? Duration.zero : const Duration(milliseconds: 300),
      reverseTransitionDuration:
          noTransition ? Duration.zero : const Duration(milliseconds: 300),
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        final page = route.settings as LiveCustomPage;
        return page.noTransition
            ? page.child
            : FadeTransition(opacity: animation, child: page.child);
      },
    );
    return route;
  }
}
