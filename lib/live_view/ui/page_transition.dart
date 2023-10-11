import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomPageTransition extends MaterialPage {
  const CustomPageTransition({
    required super.child,
    super.maintainState = true,
    super.fullscreenDialog = false,
    super.allowSnapshotting = true,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });
}

class PageTransition<T> extends MaterialPageRoute<T> {
  PageTransition({required WidgetBuilder builder, RouteSettings? settings})
      : super(builder: builder, settings: settings);

  @override
  get transitionDuration => const Duration(milliseconds: 250);

  @override
  Widget buildTransitions(BuildContext context, Animation<double> animation,
      Animation<double> secondaryAnimation, Widget child) {
    return CupertinoPageTransition(
      primaryRouteAnimation: animation,
      secondaryRouteAnimation: secondaryAnimation,
      linearTransition: true,
      child: child,
    );
  }
}
