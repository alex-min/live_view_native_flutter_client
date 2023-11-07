import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/exec/exec_show_bottom_sheet.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/exec/exec_go_back.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/exec_live_patch.dart';
import 'package:liveview_flutter/exec/exec_save_current_theme.dart';
import 'package:liveview_flutter/exec/exec_switch_theme.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_scaffold.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class StateEvents {
  static void convertExecsToEventHandler(BuildContext context,
      List<EventHandler> events, List<Exec> actions, StateWidget widget) {
    var liveView = widget.liveView;
    for (var action in actions) {
      if (action.conditions.execute(context) == false) {
        if (action is ExecHideAction && action.conditions.isNotEmpty) {
          var showAction = ExecShowAction(
              to: action.to, timeInMilliseconds: action.timeInMilliseconds);
          events.add((_) {
            if (showAction.to != null) {
              liveView.eventHub.fire('globalAction', showAction);
            } else {
              widget.show(showAction);
            }
          });
        } else if (action is ExecShowAction && action.conditions.isNotEmpty) {
          var hideAction = ExecHideAction(
              to: action.to, timeInMilliseconds: action.timeInMilliseconds);
          events.add((_) {
            if (hideAction.to != null) {
              liveView.eventHub.fire('globalAction', hideAction);
            } else {
              widget.hide(hideAction);
            }
          });
        }
        continue;
      }
      switch (action) {
        case final ExecLivePatch event:
          events.add((_) => liveView.livePatch(event.url));
        case final ExecLiveEvent event:
          events.add((_) => liveView.sendEvent(event));
        case final ExecGoBack _:
          events.add((_) => liveView.goBack());
        case final ExecSwitchTheme event:
          events.add((_) => liveView.switchTheme(event.theme, event.mode));
        case final ExecSaveCurrentTheme _:
          events.add((_) => liveView.saveCurrentTheme());
        case final ExecShowAction event:
          events.add((_) {
            if (event.to != null) {
              liveView.eventHub.fire('globalAction', event);
            } else {
              widget.show(event);
            }
          });
        case final ExecHideAction event:
          events.add((_) {
            if (event.to != null) {
              liveView.eventHub.fire('globalAction', event);
            } else {
              widget.hide(event);
            }
          });
        case final ExecShowBottomSheet _:
          events.add(
              (context) => ShowBottomSheetNotification().dispatch(context));
        default:
          reportError("unknown action $action");
      }
    }
  }
}
