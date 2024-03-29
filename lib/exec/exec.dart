import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';
import 'package:liveview_flutter/when/when.dart';

/// Represents an action that can be executed in the view.
///
/// It can be an event or a command, like changing the current theme or switching pages.
abstract class Exec {
  When conditions = When();

  void conditionalHandler(BuildContext context, StateWidget widget) {
    if (conditions.execute(context) == false) return;
    handler(context, widget);
  }

  void handler(BuildContext context, StateWidget widget) {
    reportError("Unimplemented action handler: $this");
  }
}
