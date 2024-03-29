import 'package:flutter/widgets.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

sealed class ExecVisibilityAction extends Exec {
  String? to;
  int? timeInMilliseconds;

  ExecVisibilityAction({
    required String? to,
    required this.timeInMilliseconds,
  }) {
    this.to = to?.replaceAll('#', '');
  }

  @override
  void conditionalHandler(BuildContext context, StateWidget widget) {
    if (conditions.execute(context)) {
      return handler(context, widget);
    }

    if (conditions.isNotEmpty) {
      var inverseActionClass = switch (this) {
        (ExecShowAction _) => ExecHideAction.new,
        (ExecHideAction _) => ExecShowAction.new,
      };

      inverseActionClass(
        to: to,
        timeInMilliseconds: timeInMilliseconds,
      ).handler(context, widget);
    }
  }

  @override
  String toString() =>
      'ExecVisibilityAction(to: $to, timeInMilliseconds: $timeInMilliseconds)';
}

class ExecShowAction extends ExecVisibilityAction {
  ExecShowAction({required super.to, required super.timeInMilliseconds});

  @override
  void handler(BuildContext context, StateWidget widget) {
    if (to != null) {
      widget.liveView.eventHub.fire('globalAction', this);
    } else {
      widget.show(this);
    }
  }
}

class ExecHideAction extends ExecVisibilityAction {
  ExecHideAction({required super.to, required super.timeInMilliseconds});

  @override
  void handler(BuildContext context, StateWidget widget) {
    if (to != null) {
      widget.liveView.eventHub.fire('globalAction', this);
    } else {
      widget.hide(this);
    }
  }
}
