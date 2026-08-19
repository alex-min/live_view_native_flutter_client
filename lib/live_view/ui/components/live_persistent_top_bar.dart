import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LivePersistentTopBar extends LiveStateWidget<LivePersistentTopBar> {
  const LivePersistentTopBar({super.key, required super.state});

  @override
  State<LivePersistentTopBar> createState() => _LivePersistentTopBarState();
}

class _LivePersistentTopBarState extends StateWidget<LivePersistentTopBar> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) => singleChild();
}
