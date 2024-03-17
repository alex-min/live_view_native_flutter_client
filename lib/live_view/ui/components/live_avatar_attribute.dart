import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveAvatarAttribute extends LiveStateWidget<LiveAvatarAttribute> {
  const LiveAvatarAttribute({super.key, required super.state});

  @override
  State<LiveAvatarAttribute> createState() => _LiveAvatarAttributeState();
}

class _LiveAvatarAttributeState extends StateWidget<LiveAvatarAttribute> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) => singleChild();
}
