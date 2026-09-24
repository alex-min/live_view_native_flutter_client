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
    return PageRouteBuilder(
      settings: this,
      pageBuilder: (
        BuildContext context,
        Animation<double> animation,
        Animation<double> secondaryAnimation,
      ) {
        return noTransition
            ? child
            : FadeTransition(opacity: animation, child: child);
      },
    );
  }
}
