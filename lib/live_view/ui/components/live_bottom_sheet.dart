import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveBottomSheet extends LiveStateWidget<LiveBottomSheet> {
  const LiveBottomSheet({super.key, required super.state});

  @override
  State<LiveBottomSheet> createState() => _LiveBottomSheetState();
}

class _LiveBottomSheetState extends StateWidget<LiveBottomSheet> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) => singleChild();
}
