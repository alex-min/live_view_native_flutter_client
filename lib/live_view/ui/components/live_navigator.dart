import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveNavigator extends LiveStateWidget<LiveNavigator> {
  const LiveNavigator({super.key, required super.state});

  @override
  State<LiveNavigator> createState() => _LiveNavigatorState();
}

class _LiveNavigatorState extends StateWidget<LiveNavigator> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return Navigator(
      pages: [MaterialPage(child: singleChild())],
      onPopPage: (route, result) {
        return false;
      },
    );
  }
}
