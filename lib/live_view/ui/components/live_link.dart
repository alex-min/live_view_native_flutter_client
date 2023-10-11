import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveLink extends LiveStateWidget<LiveLink> {
  const LiveLink({super.key, required super.state});

  @override
  State<LiveLink> createState() => _LiveCenterState();
}

class _LiveCenterState extends StateWidget<LiveLink> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(['patch']);
  }

  @override
  Widget render(BuildContext context) {
    var patchUrl = getAttribute('patch');
    if (patchUrl == null) {
      return singleChild();
    }

    return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () {
          liveView.redirectTo(patchUrl);
          liveView.router
              .pushPage(url: 'loading', widget: liveView.loadingWidget());
        },
        child: AbsorbPointer(child: singleChild()));
  }
}
