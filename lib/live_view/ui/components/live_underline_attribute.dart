import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveUnderlineAttribute extends LiveStateWidget<LiveUnderlineAttribute> {
  const LiveUnderlineAttribute({super.key, required super.state});

  @override
  State<LiveUnderlineAttribute> createState() => _LiveUnderlineAttributeState();
}

class _LiveUnderlineAttributeState extends StateWidget<LiveUnderlineAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
