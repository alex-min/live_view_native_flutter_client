import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecNavigate extends Exec {
  String url;

  ExecNavigate({required this.url});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.livePatch(url);
  }
}
