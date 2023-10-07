import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveCenter extends LiveStateWidget {
  const LiveCenter({super.key, required super.state});

  @override
  State<LiveCenter> createState() => _LiveCenterState();
}

class _LiveCenterState extends StateWidget<LiveCenter> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Center(child: singleChild());
  }
}
