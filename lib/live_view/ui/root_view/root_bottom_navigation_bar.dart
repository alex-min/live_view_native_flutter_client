import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class RootBottomNavigationBar extends StatefulWidget {
  final LiveView view;
  const RootBottomNavigationBar({super.key, required this.view});

  @override
  State<RootBottomNavigationBar> createState() =>
      _RootBottomNavigationBarState();
}

class _RootBottomNavigationBarState extends State<RootBottomNavigationBar> {
  Widget? bar;

  @override
  void initState() {
    widget.view.router.addListener(routeChange);

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void routeChange() {
    setState(() {});
  }

  T? extractChild<T extends LiveStateWidget>(List<Widget> children) {
    for (var child in children) {
      if (child is T) {
        return child;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.view.router.pages.last.containsGlobalNavigationWidgets) {
      bar = extractChild<LiveBottomNavigationBar>(
          widget.view.router.pages.last.widgets);
      bar ??=
          extractChild<LiveBottomAppBar>(widget.view.router.pages.last.widgets);
    } else {
      bar = null;
    }
    return bar ?? const SizedBox.shrink();
  }
}
