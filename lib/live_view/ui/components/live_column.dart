import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveColumn extends LiveStateWidget<LiveColumn> {
  const LiveColumn({super.key, required super.state});

  @override
  State<LiveColumn> createState() => _LiveColState();
}

class _LiveColState extends StateWidget<LiveColumn> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Column(children: multipleChildren());
  }
}
