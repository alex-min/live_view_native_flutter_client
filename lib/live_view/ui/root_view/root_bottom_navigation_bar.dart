import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
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
  LiveBottomNavigationBar? bar;

  @override
  void initState() {
    widget.view.router.addListener(routeChange);

    super.initState();
  }

  void routeChange() {
    setState(() {
      bar = extractChild<LiveBottomNavigationBar>(
          widget.view.router.pages.last.widgets);
    });
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
    return bar ?? const SizedBox.shrink();
  }
}
