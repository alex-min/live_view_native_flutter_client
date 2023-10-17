import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class RootAppBar extends StatefulWidget implements PreferredSizeWidget {
  final LiveView view;
  const RootAppBar({super.key, required this.view})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize;

  @override
  State<RootAppBar> createState() => _RootAppBarState();
}

class _RootAppBarState extends State<RootAppBar> {
  LiveAppBar? bar;

  @override
  void initState() {
    widget.view.router.addListener(routeChange);
    super.initState();
  }

  void routeChange() {
    if (mounted) {
      setState(() {
        bar = extractChild<LiveAppBar>(widget.view.router.pages.last.widgets);
      });
    }
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
    return bar != null
        ? Container(key: const Key('main_app_bar'), child: bar)
        : const SizedBox.shrink();
  }
}
