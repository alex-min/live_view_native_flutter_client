import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveElevatedButton extends LiveStateWidget<LiveElevatedButton> {
  const LiveElevatedButton({super.key, required super.state});

  @override
  State<LiveElevatedButton> createState() => _LiveElevatedButtonState();
}

class _LiveElevatedButtonState extends StateWidget<LiveElevatedButton> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['type']);
  }

  @override
  handleClickState() => HandleClickState.manual;

  @override
  Widget render(BuildContext context) {
    return ElevatedButton(
        onPressed: () {
          if (getAttribute('type') == 'submit') {
            widget.state.formEvents?.onSave();
          }
          executeTapEventsManually();
        },
        child: singleChild());
  }
}
