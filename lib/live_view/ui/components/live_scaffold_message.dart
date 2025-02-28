import 'dart:async';

import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveScaffoldMessage extends LiveStateWidget<LiveScaffoldMessage> {
  const LiveScaffoldMessage({super.key, required super.state});

  @override
  State<LiveScaffoldMessage> createState() => _LiveScaffoldMessageState();
}

class _LiveScaffoldMessageState extends StateWidget<LiveScaffoldMessage> {
  Timer? timer;
  bool rendered = false;

  @override
  void onFormInitialize() {
    if (widget.state.viewType == ViewType.deadView &&
        widget.state.liveView.clientType == ClientType.liveView) {
      return;
    }

    Future.microtask(() {
      ScaffoldMessenger.of(context).clearSnackBars();
      showScaffold();
    });
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node,
        ['kind', 'showCloseIcon', 'backgroundColor', 'duration', 'http-clear']);
  }

  @override
  Widget render(BuildContext context) {
    Future.microtask(() => showScaffold());
    return const SizedBox.shrink();
  }

  void showScaffold() {
    if (rendered) {
      return;
    }
    rendered = true;
    String? kind = getAttribute('kind');
    bool showCloseIcon = booleanAttribute('showCloseIcon') ?? true;
    Color? backgroundColor = colorAttribute(context, 'backgroundColor') ??
        Theme.of(context).snackBarTheme.backgroundColor;
    Duration duration =
        durationAttribute('duration') ?? const Duration(milliseconds: 4000);

    if (kind != null) {
      final newTimer = Timer(duration, () => closeScaffold(kind));
      timer?.cancel();
      timer = newTimer;
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: singleChild(),
              duration: duration,
              showCloseIcon: showCloseIcon,
              backgroundColor: backgroundColor,
            ),
          )
          .closed
          .then((_) => newTimer == timer ? closeScaffold(kind) : null);
    }
  }

  void closeScaffold(String kind) {
    timer?.cancel();
    timer = null;
    widget.state.liveView.sendEvent(ExecLiveEvent(
      type: 'click',
      name: "lv:clear-flash",
      value: {"key": kind},
    ));

    var clear = getAttribute('http-clear');
    if (clear != null) {
      liveView.httpPost(clear, {'kind': kind});
    }
  }
}
