import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveTextbutton extends LiveStateWidget {
  const LiveTextbutton({super.key, required super.state});

  @override
  State<LiveTextbutton> createState() => _LiveSubmitbuttonState();
}

class _LiveSubmitbuttonState extends StateWidget<LiveTextbutton> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(['type']);
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
          handlePhxClick();
        },
        child: singleChild());
  }
}
