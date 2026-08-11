import 'package:flutter/material.dart';
import 'package:liveview_flutter/exec/exec_live_event.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_content_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveModal extends LiveStateWidget<LiveModal> {
  const LiveModal({super.key, required super.state});

  @override
  State<LiveModal> createState() => _LiveModalState();
}

class _LiveModalState extends StateWidget<LiveModal> {
  NavigatorState? rootNavigator;
  bool isPresented = false;
  bool closingProgrammatically = false;
  bool closeEventSent = false;

  @override
  void initState() {
    super.initState();
    rootNavigator = Navigator.of(context, rootNavigator: true);
    Future.microtask(showModal);
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['close-event', 'fullscreen', 'presentation']);
  }

  @override
  Widget render(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    closingProgrammatically = true;
    Future.microtask(hideModal);
    super.dispose();
  }

  void hideModal() {
    if (isPresented && rootNavigator != null && rootNavigator!.canPop()) {
      rootNavigator?.pop();
    }
  }

  void showModal() {
    if (getAttribute('presentation') == 'bottomSheet') {
      showBottomSheet();
      return;
    }

    bool fullscreen = booleanAttribute('fullscreen') ?? true;
    isPresented = true;
    rootNavigator!.push(
      MaterialPageRoute(
        fullscreenDialog: fullscreen,
        builder: (_) {
          var children = multipleChildren();
          var title = StateChild.extractChild<LiveTitleAttribute>(children);
          var content = StateChild.extractChild<LiveContentAttribute>(children);

          return PopScope(
            canPop: false,
            onPopInvoked: (bool didPop) {
              if (didPop) {
                return;
              }
              sendCloseEvent();
            },
            child: Scaffold(
              appBar:
                  title != null
                      ? PreferredSize(
                        preferredSize: const Size.fromHeight(kToolbarHeight),
                        child: title,
                      )
                      : null,
              body: content,
            ),
          );
        },
      ),
    );
  }

  void showBottomSheet() {
    isPresented = true;
    showModalBottomSheet<void>(
      context: rootNavigator!.context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) {
        var children = multipleChildren();
        var title = StateChild.extractChild<LiveTitleAttribute>(children);
        var content = StateChild.extractChild<LiveContentAttribute>(children);

        return SafeArea(
          child: FractionallySizedBox(
            heightFactor: 0.85,
            child: Scaffold(
              appBar:
                  title != null
                      ? PreferredSize(
                        preferredSize: const Size.fromHeight(kToolbarHeight),
                        child: title,
                      )
                      : null,
              body: content,
            ),
          ),
        );
      },
    ).then((_) {
      isPresented = false;
      if (!closingProgrammatically) {
        sendCloseEvent();
      }
    });
  }

  void sendCloseEvent() {
    if (closeEventSent) {
      return;
    }
    closeEventSent = true;
    widget.state.liveView.sendEvent(
      ExecLiveEvent(
        type: 'event',
        name: getAttribute('close-event') ?? 'hide',
        value: {},
      ),
    );
  }
}
