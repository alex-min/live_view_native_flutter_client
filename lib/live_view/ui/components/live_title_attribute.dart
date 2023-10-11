import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveTitleAttribute extends LiveStateWidget<LiveTitleAttribute> {
  const LiveTitleAttribute({super.key, required super.state});

  @override
  State<LiveTitleAttribute> createState() => _LiveTitleState();
}

class _LiveTitleState extends StateWidget<LiveTitleAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
