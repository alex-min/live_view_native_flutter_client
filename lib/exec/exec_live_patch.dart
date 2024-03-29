import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecLivePatch extends Exec {
  String url;

  ExecLivePatch({required this.url});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.livePatch(url);
  }
}
