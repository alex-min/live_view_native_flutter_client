import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecSwitchTheme extends Exec {
  String theme;
  String mode;

  ExecSwitchTheme({required this.theme, required this.mode});

  @override
  void handler(BuildContext context, StateWidget widget) {
    widget.liveView.switchTheme(theme, mode);
  }
}
