import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/alignment_directional.dart';
import 'package:liveview_flutter/live_view/mapping/decoration.dart';
import 'package:liveview_flutter/live_view/mapping/edge_insets.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveContainer extends LiveStateWidget<LiveContainer> {
  const LiveContainer({super.key, required super.state});

  @override
  State<LiveContainer> createState() => _LiveContainerState();
}

class _LiveContainerState extends StateWidget<LiveContainer> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node,
      ['margin', 'padding', 'decoration', 'height', 'width', 'alignment']);

  @override
  Widget render(BuildContext context) {
    return Container(
      alignment: getAlignmentDirectional('alignment'),
      height: doubleAttribute('height'),
      width: doubleAttribute('width'),
      margin: getEdgeInsets(getAttribute('margin')),
      padding: getEdgeInsets(getAttribute('padding')),
      decoration: getDecoration(context, getAttribute('decoration')),
      child: singleChild(),
    );
  }
}
