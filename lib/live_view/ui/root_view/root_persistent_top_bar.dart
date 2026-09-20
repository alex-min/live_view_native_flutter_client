import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
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

    if (bar == null) {
      return const SizedBox.shrink();
    }

    // Paint the status-bar inset with the bar's own background color (when
    // the server provides one) so no foreign background shows through above
    // the bar.
    final backgroundColor = getColor(
      context,
      bar!.state.node.getAttribute('backgroundColor'),
    );
    final padded = SafeArea(bottom: false, child: bar!);
    return backgroundColor == null
        ? padded
        : Container(color: backgroundColor, child: padded);
  }
}
