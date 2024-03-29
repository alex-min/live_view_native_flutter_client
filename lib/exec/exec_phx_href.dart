import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecPhxHref extends Exec {
  String url;

  ExecPhxHref({required this.url});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.execHrefClick(url);
  }
}

class ExecPhxHrefModal extends Exec {
  String url;

  ExecPhxHrefModal({required this.url});

  @override
  void handler(BuildContext context, StateWidget widget) {
    Navigator.of(context).pop();
    widget.liveView.execHrefClick(url);
  }
}
