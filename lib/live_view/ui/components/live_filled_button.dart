import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveFilledButton extends LiveStateWidget<LiveFilledButton> {
  const LiveFilledButton({super.key, required super.state});

  @override
  State<LiveFilledButton> createState() => _LiveFilledButtonState();
}

class _LiveFilledButtonState extends StateWidget<LiveFilledButton> {
  @override
  handleClickState() => HandleClickState.manual;

  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return FilledButton(
        onPressed: () {
          executeTapEventsManually();
        },
        child: singleChild());
  }
}
