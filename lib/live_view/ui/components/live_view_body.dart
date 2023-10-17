import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveViewBody extends LiveStateWidget<LiveViewBody> {
  const LiveViewBody({super.key, required super.state});

  @override
  State<LiveViewBody> createState() => _LiveMainViewState();
}

class _LiveMainViewState extends StateWidget<LiveViewBody> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return singleChild();
  }
}
