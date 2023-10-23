import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LivePositioned extends LiveStateWidget<LivePositioned> {
  const LivePositioned({super.key, required super.state});

  @override
  State<LivePositioned> createState() => _LivePositionedState();
}

class _LivePositionedState extends StateWidget<LivePositioned> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(
        node, ['left', 'top', 'right', 'bottom', 'width', 'height']);
  }

  @override
  Widget render(BuildContext context) {
    return Positioned(
      left: doubleAttribute('left'),
      top: doubleAttribute('top'),
      right: doubleAttribute('right'),
      bottom: doubleAttribute('bottom'),
      width: doubleAttribute('width'),
      height: doubleAttribute('height'),
      child: singleChild(),
    );
  }
}
