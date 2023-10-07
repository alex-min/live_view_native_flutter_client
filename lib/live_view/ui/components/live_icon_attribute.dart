import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveIconAttribute extends LiveStateWidget {
  const LiveIconAttribute({super.key, required super.state});

  @override
  State<LiveIconAttribute> createState() => _LiveIconAttributeState();
}

class _LiveIconAttributeState extends StateWidget<LiveIconAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
