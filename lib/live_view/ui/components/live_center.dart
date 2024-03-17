import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveCenter extends LiveStateWidget<LiveCenter> {
  const LiveCenter({super.key, required super.state});

  @override
  State<LiveCenter> createState() => _LiveCenterState();
}

class _LiveCenterState extends StateWidget<LiveCenter> {
  final attributes = ['widthFactor', 'heightFactor'];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return Center(
        widthFactor: doubleAttribute('widthFactor'),
        heightFactor: doubleAttribute('heightFactor'),
        child: singleChild());
  }
}
