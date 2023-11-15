import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveTrailingAttribute extends LiveStateWidget<LiveTrailingAttribute> {
  const LiveTrailingAttribute({super.key, required super.state});

  @override
  State<LiveTrailingAttribute> createState() => _LiveTitleState();
}

class _LiveTitleState extends StateWidget<LiveTrailingAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
