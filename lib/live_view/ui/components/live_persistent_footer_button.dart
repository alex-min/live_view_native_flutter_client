import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LivePersistentFooterButton
    extends LiveStateWidget<LivePersistentFooterButton> {
  const LivePersistentFooterButton({super.key, required super.state});

  @override
  State<LivePersistentFooterButton> createState() =>
      _LivePersistentFooterButtonState();
}

class _LivePersistentFooterButtonState
    extends StateWidget<LivePersistentFooterButton> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
