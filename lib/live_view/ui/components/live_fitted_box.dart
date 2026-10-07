import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

/// Shrink long text (or another child) to fit without clipping or truncating.
class LiveFittedBox extends LiveStateWidget<LiveFittedBox> {
  const LiveFittedBox({super.key, required super.state});
  @override
  State<LiveFittedBox> createState() => _FittedBoxState();
}

class _FittedBoxState extends StateWidget<LiveFittedBox> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}
  @override
  Widget render(BuildContext context) =>
      FittedBox(fit: BoxFit.scaleDown, child: singleChild());
}
