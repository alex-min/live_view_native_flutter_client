import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveSubtitleAttribute extends LiveStateWidget<LiveSubtitleAttribute> {
  const LiveSubtitleAttribute({super.key, required super.state});

  @override
  State<LiveSubtitleAttribute> createState() => _LiveTitleState();
}

class _LiveTitleState extends StateWidget<LiveSubtitleAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
