import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_cosmic_background.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveViewBody extends LiveStateWidget<LiveViewBody> {
  const LiveViewBody({super.key, required super.state});

  @override
  State<LiveViewBody> createState() => _LiveMainViewState();
}

class _LiveMainViewState extends StateWidget<LiveViewBody> {
  final attributes = ['cosmicBackground'];

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    // Only the current page's body render counts towards the
    // persistent-chrome drop decision; stale pages in the navigator stack
    // can rebuild while hidden.
    if (widget.state.isOnTheCurrentPage) {
      widget.state.liveView.persistentChromePageRendered = true;
    }
    final child = singleChild();
    // A hidden or compact app bar leaves the status bar uncovered: pad the
    // page content, keeping ambient backgrounds (painted below) edge-to-edge.
    final padded =
        widget.state.liveView.padBodyBelowStatusBar
            ? SafeArea(child: child)
            : child;
    if (getAttribute('cosmicBackground') != 'true') return padded;

    return Stack(
      children: [
        Positioned.fill(
          child: LiveCosmicBackground(state: widget.state, key: widget.key),
        ),
        Positioned.fill(child: padded),
      ],
    );
  }
}
