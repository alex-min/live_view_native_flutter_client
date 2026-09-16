import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecLivePatch extends Exec {
  String url;
  bool replace;

  ExecLivePatch({required this.url, this.replace = false});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.livePatch(url, replace: replace);
  }
}
