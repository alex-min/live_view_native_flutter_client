import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveStack extends LiveStateWidget<LiveStack> {
  const LiveStack({super.key, required super.state});

  @override
  State<LiveStack> createState() => _LiveStackState();
}

class _LiveStackState extends StateWidget<LiveStack> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Stack(children: multipleChildren());
  }
}
