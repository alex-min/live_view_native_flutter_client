import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveExpanded extends LiveStateWidget<LiveExpanded> {
  const LiveExpanded({super.key, required super.state});

  @override
  State<LiveExpanded> createState() => _LiveExpandedState();
}

class _LiveExpandedState extends StateWidget<LiveExpanded> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Expanded(child: singleChild());
  }
}
