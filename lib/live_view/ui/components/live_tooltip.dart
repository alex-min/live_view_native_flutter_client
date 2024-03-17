import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveTooltip extends LiveStateWidget<LiveTooltip> {
  const LiveTooltip({super.key, required super.state});

  @override
  State<LiveTooltip> createState() => _LiveTooltipState();
}

class _LiveTooltipState extends StateWidget<LiveTooltip> {
  final attributes = [
    'message',
    'height',
    'padding',
    'margin',
    'verticalOffset',
    'preferBelow',
    'excludeFromSemantics',
    'decoration',
    'textStyle',
    'textAlign',
    'waitDuration',
    'showDuration',
    'triggerMode',
    'enableFeedback'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return Tooltip(
      message: getAttribute('message') ?? '',
      richMessage: null, // TODO: InlineSpan
      height: doubleAttribute('height'),
      padding: marginOrPaddingAttribute('padding'),
      margin: marginOrPaddingAttribute('margin'),
      verticalOffset: doubleAttribute('verticalOffset'),
      preferBelow: booleanAttribute('preferBelow'),
      excludeFromSemantics: booleanAttribute('excludeFromSemantics'),
      decoration: decorationAttribute(context, 'decoration'),
      textStyle: textStyleAttribute('textStyle', context),
      textAlign: textAlignAttribute('textAlign'),
      waitDuration: durationAttribute('waitDuration'),
      showDuration: durationAttribute('showDuration'),
      triggerMode: tooltipTriggerModeAttribute('triggerMode'),
      enableFeedback: booleanAttribute('enableFeedback'),
      onTriggered: () => executeOnTriggerEventsManually(),
      child: singleChild(),
    );
  }
}
