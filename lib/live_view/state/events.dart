import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/exec/exec_go_back.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/exec/exec_live_patch.dart';
import 'package:liveview_flutter/exec/exec_save_current_theme.dart';
import 'package:liveview_flutter/exec/exec_switch_theme.dart';
import 'package:liveview_flutter/exec/exec_visibility_action.dart';
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
          events.add((BuildContext context) {
            if (showAction.to != null) {
              liveView.eventHub.fire('globalAction', showAction);
            } else {
              widget.show(showAction);
            }
          });
        } else if (action is ExecShowAction && action.conditions.isNotEmpty) {
          var hideAction = ExecHideAction(
              to: action.to, timeInMilliseconds: action.timeInMilliseconds);
          events.add((BuildContext context) {
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
          events.add((_) {
            liveView.router.pushPage(
                url: 'loading;${event.url}', widget: liveView.loadingWidget());
            liveView.redirectTo(event.url);
          });
        case final ExecLiveEvent event:
          events.add((_) {
            liveView.sendEvent(event);
          });
        case final ExecGoBack _:
          events.add((BuildContext context) {
            liveView.router.navigatorKey?.currentState?.maybePop();
            liveView.router.notify();
          });
        case final ExecSwitchTheme event:
          events.add((BuildContext context) {
            liveView.switchTheme(event.theme, event.mode);
          });
        case final ExecSaveCurrentTheme _:
          events.add((BuildContext context) {
            liveView.saveCurrentTheme();
          });
        case final ExecShowAction event:
          events.add((BuildContext context) {
            if (event.to != null) {
              liveView.eventHub.fire('globalAction', event);
            } else {
              widget.show(event);
            }
          });
        case final ExecHideAction event:
          events.add((BuildContext context) {
            if (event.to != null) {
              liveView.eventHub.fire('globalAction', event);
            } else {
              widget.hide(event);
            }
          });
        default:
          reportError("unknown action $action");
      }
    }
  }
}
