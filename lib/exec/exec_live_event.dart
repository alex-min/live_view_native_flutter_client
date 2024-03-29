import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec_confirmable.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecLiveEvent extends ExecConfirmable {
  final String type;
  final String name;
  final dynamic value;

  ExecLiveEvent({
    required this.type,
    required this.name,
    required this.value,
    super.dataConfirm,
  });

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.sendEvent(this);
  }
}
