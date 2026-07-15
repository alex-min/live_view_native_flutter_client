import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecPhxHref extends Exec {
  String url;
  String method;

  ExecPhxHref({required this.url, this.method = 'GET'});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.execHrefClick(url, method: method);
  }
}

class ExecPhxHrefModal extends Exec {
  String url;
  String method;

  ExecPhxHrefModal({required this.url, this.method = 'GET'});

  @override
  void handler(BuildContext context, StateWidget widget) {
    Navigator.of(context).pop();
    widget.liveView.execHrefClick(url, method: method);
  }
}
