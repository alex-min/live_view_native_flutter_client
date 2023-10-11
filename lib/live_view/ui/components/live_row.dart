import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveRow extends LiveStateWidget<LiveRow> {
  const LiveRow({super.key, required super.state});

  @override
  State<LiveRow> createState() => _LiveColState();
}

class _LiveColState extends StateWidget<LiveRow> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Row(children: multipleChildren());
  }
}
