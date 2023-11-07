import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveBottomAppBar extends LiveStateWidget<LiveBottomAppBar> {
  const LiveBottomAppBar({super.key, required super.state});

  @override
  State<LiveBottomAppBar> createState() => _LiveBottomAppBarState();
}

class _LiveBottomAppBarState extends StateWidget<LiveBottomAppBar> {
  final attributes = [
    'color',
    'elevation',
    'clipBehavior',
    'padding',
    'color',
    'elevation',
    'shape',
    'height'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return BottomAppBar(
        height: doubleAttribute('height'),
        clipBehavior: clipAttribute('clipBehavior') ?? Clip.none,
        padding: marginOrPaddingAttribute('padding'),
        shape: notchedShapeAttribute('shape'),
        color: colorAttribute(context, 'color'),
        elevation: doubleAttribute('elevation'),
        surfaceTintColor: colorAttribute(context, 'surfaceTintColor'),
        shadowColor: colorAttribute(context, 'shadowColor'),
        child: singleChild());
  }
}
