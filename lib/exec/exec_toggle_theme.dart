import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class ExecToggleTheme extends Exec {
  @override
  void handler(BuildContext context, StateWidget widget) {
    var currentMode = widget.liveView.themeSettings.getDisplayedThemeMode();
    var nextMode = currentMode == ThemeMode.dark ? 'light' : 'dark';
    widget.liveView.switchTheme('default', nextMode);
  }
}
