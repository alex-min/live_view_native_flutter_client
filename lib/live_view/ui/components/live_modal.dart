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

  @override
  void initState() {
    super.initState();
    rootNavigator = Navigator.of(context, rootNavigator: true);
    Future.microtask(showModal);
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['close-event', 'fullscreen']);
  }

  @override
  Widget render(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    Future.microtask(hideModal);
    super.dispose();
  }

  void hideModal() {
    if (rootNavigator != null && rootNavigator!.canPop()) {
      rootNavigator?.pop();
    }
  }

  void showModal() {
    bool fullscreen = booleanAttribute('fullscreen') ?? true;
    String closeEvent = getAttribute('close-event') ?? 'hide';
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
              widget.state.liveView.sendEvent(ExecLiveEvent(
                type: 'event',
                name: closeEvent,
                value: {},
              ));
            },
            child: Scaffold(
              appBar: title != null
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
}
