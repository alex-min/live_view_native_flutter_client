import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveLeadingAttribute extends LiveStateWidget<LiveLeadingAttribute> {
  const LiveLeadingAttribute({super.key, required super.state});

  @override
  State<LiveLeadingAttribute> createState() => _LiveLeadingState();
}

class _LiveLeadingState extends StateWidget<LiveLeadingAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
