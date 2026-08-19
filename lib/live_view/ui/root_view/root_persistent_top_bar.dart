import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/live_persistent_top_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class RootPersistentTopBar extends StatefulWidget {
  final LiveView view;

  const RootPersistentTopBar({super.key, required this.view});

  @override
  State<RootPersistentTopBar> createState() => _RootPersistentTopBarState();
}

class _RootPersistentTopBarState extends State<RootPersistentTopBar> {
  LivePersistentTopBar? bar;

  @override
  void initState() {
    widget.view.router.addListener(routeChange);
    super.initState();
  }

  @override
  void dispose() {
    widget.view.router.removeListener(routeChange);
    super.dispose();
  }

  void routeChange() {
    if (mounted) {
      setState(() {
        bar = extractChild<LivePersistentTopBar>(
          widget.view.router.pages.last.widgets,
        );
      });
    }
  }

  T? extractChild<T extends LiveStateWidget>(List<Widget> children) {
    for (final child in children) {
      if (child is T) {
        return child;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    bar ??= extractChild<LivePersistentTopBar>(
      widget.view.router.pages.last.widgets,
    );

    return bar == null
        ? const SizedBox.shrink()
        : SafeArea(bottom: false, child: bar!);
  }
}
