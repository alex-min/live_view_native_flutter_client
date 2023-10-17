import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveLink extends LiveStateWidget<LiveLink> {
  const LiveLink({super.key, required super.state});

  @override
  State<LiveLink> createState() => _LiveCenterState();
}

class _LiveCenterState extends StateWidget<LiveLink> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return MouseRegion(cursor: SystemMouseCursors.click, child: singleChild());
  }
}
