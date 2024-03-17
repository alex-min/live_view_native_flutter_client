import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDisabledHintAttribute
    extends LiveStateWidget<LiveDisabledHintAttribute> {
  const LiveDisabledHintAttribute({super.key, required super.state});

  @override
  State<LiveDisabledHintAttribute> createState() =>
      _LiveDisabledHintAttributeState();
}

class _LiveDisabledHintAttributeState
    extends StateWidget<LiveDisabledHintAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
