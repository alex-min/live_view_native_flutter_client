import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/alignment_directional.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveStack extends LiveStateWidget<LiveStack> {
  const LiveStack({super.key, required super.state});

  @override
  State<LiveStack> createState() => _LiveStackState();
}

class _LiveStackState extends StateWidget<LiveStack> {
  final attributes = ['clipBehavior', 'alignment'];

  @override
  void initState() {
    super.initState();
    listenInnerTextKeys();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
  }

  @override
  Widget render(BuildContext context) {
    return Stack(
      alignment:
          getAlignmentDirectional(getAttribute('alignment')) ??
          AlignmentDirectional.topStart,
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.hardEdge,
      children: flexChildren(),
    );
  }

  @override
  Clip? clipAttribute(String name) {
    switch (getAttribute(name)) {
      case 'none':
        return Clip.none;
      case 'antiAlias':
        return Clip.antiAlias;
      case 'antiAliasWithSaveLayer':
        return Clip.antiAliasWithSaveLayer;
      case 'hardEdge':
        return Clip.hardEdge;
      default:
        return null;
    }
  }
}
