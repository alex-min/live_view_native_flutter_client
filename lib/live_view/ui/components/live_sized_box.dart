import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveSizedBox extends LiveStateWidget<LiveSizedBox> {
  const LiveSizedBox({super.key, required super.state});

  @override
  State<LiveSizedBox> createState() => _LiveSizedBoxState();
}

class _LiveSizedBoxState extends StateWidget<LiveSizedBox> {
  final attributes = ['height', 'width'];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return SizedBox(
      height: doubleAttribute('height'),
      width: doubleAttribute('width'),
      child: singleChild(),
    );
  }
}
