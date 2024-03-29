import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_scaffold.dart';

class ExecShowBottomSheet extends Exec {
  @override
  void handler(BuildContext context, StateWidget widget) {
    ShowBottomSheetNotification().dispatch(context);
  }
}
