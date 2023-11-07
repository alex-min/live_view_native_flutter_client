import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveContentAttribute extends LiveStateWidget<LiveContentAttribute> {
  const LiveContentAttribute({super.key, required super.state});

  @override
  State<LiveContentAttribute> createState() => _LiveContentAttributeState();
}

class _LiveContentAttributeState extends StateWidget<LiveContentAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
