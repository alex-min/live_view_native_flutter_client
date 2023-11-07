import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveBadge extends LiveStateWidget<LiveBadge> {
  const LiveBadge({super.key, required super.state});

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends StateWidget<LiveBadge> {
  final attributes = [
    'backgroundColor',
    'textColor',
    'smallSize',
    'largeSize',
    'textStyle',
    'padding',
    'label',
    'isLabelVisible'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    Widget? label = StateChild.extractChild<LiveLabelAttribute>(children);
    label ??= textWidgetFromAttribute('label');
    label ??= StateChild.extractChild<LiveText>(children);

    return Badge(
      backgroundColor: colorAttribute(context, 'backgroundColor'),
      textColor: colorAttribute(context, 'textColor'),
      smallSize: doubleAttribute('smallSize'),
      largeSize: doubleAttribute('largeSize'),
      textStyle: textStyleAttribute('textStyle', context),
      padding: marginOrPaddingAttribute('padding'),
      alignment: null, // TODO: AlignmentGeometry
      offset: null, // TODO: Offset
      label: label,
      isLabelVisible: booleanAttribute('isLabelVisible') ?? true,
      child: singleChild(),
    );
  }
}
