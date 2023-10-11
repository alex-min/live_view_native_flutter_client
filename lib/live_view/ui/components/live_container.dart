import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveContainer extends LiveStateWidget<LiveContainer> {
  const LiveContainer({super.key, required super.state});

  @override
  State<LiveContainer> createState() => _LiveContainerState();
}

class _LiveContainerState extends StateWidget<LiveContainer> {
  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(['margin', 'padding', 'decoration']);

  @override
  Widget render(BuildContext context) {
    return Container(
      margin: getMarginOrPadding(getAttribute('margin')),
      padding: getMarginOrPadding(getAttribute('padding')),
      decoration: getDecoration(context, getAttribute('decoration')),
      child: singleChild(),
    );
  }
}
