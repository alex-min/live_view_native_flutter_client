import 'dart:async';

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
  StreamSubscription? _resizeSubscription;

  @override
  void initState() {
    widget.view.router.addListener(routeChange);
    _resizeSubscription = widget.view.eventHub.on('phx:window:resize', (_) {
      if (mounted) {
        setState(() {});
      }
    });

    super.initState();
  }

  @override
  void dispose() {
    widget.view.router.removeListener(routeChange);
    _resizeSubscription?.cancel();
    super.dispose();
  }

  void routeChange() {
    if (mounted) {
      setState(() {});
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
    if (widget.view.router.pages.last.containsGlobalNavigationWidgets) {
      bar = extractChild<LiveBottomNavigationBar>(
        widget.view.router.pages.last.widgets,
      );
      bar ??= extractChild<LiveBottomAppBar>(
        widget.view.router.pages.last.widgets,
      );
    } else {
      bar = null;
    }

    // The extracted navigation bar widget is created once during XML parsing.
    // Without a changing key, Flutter would treat it as the same widget across
    // rebuilds and skip calling its build even when the window size changes.
    // Keying it by the current width forces the bar to rebuild with the latest
    // MediaQuery so the mobile breakpoint is re-evaluated.
    if (bar != null) {
      return KeyedSubtree(
        key: ValueKey(MediaQuery.of(context).size.width),
        child: bar!,
      );
    }
    return const SizedBox.shrink();
  }
}
