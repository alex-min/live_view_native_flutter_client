import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveLabelAttribute extends LiveStateWidget<LiveLabelAttribute> {
  const LiveLabelAttribute({super.key, required super.state});

  @override
  State<LiveLabelAttribute> createState() => _LiveLabelAttributeState();
}

class _LiveLabelAttributeState extends StateWidget<LiveLabelAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
