import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/live_view_exec_registry.dart';
import 'package:liveview_flutter/live_view/ui/live_view_ui_registry.dart';

abstract class Plugin {
  String get name;

  void registerWidgets(LiveViewUiRegistry registry);

  void registerExecs(LiveViewExecRegistry registry);
}
