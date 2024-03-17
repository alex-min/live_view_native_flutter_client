import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveCard extends LiveStateWidget<LiveCard> {
  const LiveCard({super.key, required super.state});

  @override
  State<LiveCard> createState() => _LiveCardState();
}

class _LiveCardState extends StateWidget<LiveCard> {
  final attributes = [
    'color',
    'shadowColor',
    'surfaceTintColor',
    'elevation',
    'shape',
    'borderOnForeground',
    'margin',
    'clipBehavior',
    'semanticContainer'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return Card(
        color: colorAttribute(context, 'color'),
        shadowColor: colorAttribute(context, 'shadowColor'),
        surfaceTintColor: colorAttribute(context, 'surfaceTintColor'),
        elevation: doubleAttribute('elevation'),
        shape: shapeBorderAttribute('shape'),
        borderOnForeground: booleanAttribute('borderOnForeground') ?? true,
        margin: marginOrPaddingAttribute('margin'),
        clipBehavior: clipAttribute('clipBehavior'),
        semanticContainer: booleanAttribute('semanticContainer') ?? true,
        child: singleChild());
  }
}
