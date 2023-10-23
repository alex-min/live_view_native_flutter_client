import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveIconSelectedAttribute
    extends LiveStateWidget<LiveIconSelectedAttribute> {
  const LiveIconSelectedAttribute({super.key, required super.state});

  @override
  State<LiveIconSelectedAttribute> createState() =>
      _LiveIconSelectedAttributeState();
}

class _LiveIconSelectedAttributeState
    extends StateWidget<LiveIconSelectedAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
