import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveHintAttribute extends LiveStateWidget<LiveHintAttribute> {
  const LiveHintAttribute({super.key, required super.state});

  @override
  State<LiveHintAttribute> createState() => _LiveHintAttributeState();
}

class _LiveHintAttributeState extends StateWidget<LiveHintAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
