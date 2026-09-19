import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/text_direction.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveWrap extends LiveStateWidget<LiveWrap> {
  const LiveWrap({super.key, required super.state});

  @override
  State<LiveWrap> createState() => _LiveWrapState();
}

class _LiveWrapState extends StateWidget<LiveWrap> {
  @override
  void initState() {
    super.initState();
    listenInnerTextKeys();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
    'direction',
    'alignment',
    'spacing',
    'runAlignment',
    'runSpacing',
    'crossAxisAlignment',
    'textDirection',
    'verticalDirection',
  ]);

  @override
  Widget render(BuildContext context) {
    return Wrap(
      direction: _axis(getAttribute('direction')),
      alignment: _alignment(getAttribute('alignment')),
      spacing: double.tryParse(getAttribute('spacing') ?? '') ?? 0,
      runAlignment: _alignment(getAttribute('runAlignment')),
      runSpacing: double.tryParse(getAttribute('runSpacing') ?? '') ?? 0,
      crossAxisAlignment: _crossAlignment(getAttribute('crossAxisAlignment')),
      textDirection: getTextDirection(getAttribute('textDirection')),
      verticalDirection:
          getAttribute('verticalDirection') == 'up'
              ? VerticalDirection.up
              : VerticalDirection.down,
      children: flexChildren(),
    );
  }

  Axis _axis(String? value) =>
      value == 'vertical' ? Axis.vertical : Axis.horizontal;

  WrapAlignment _alignment(String? value) {
    switch (value) {
      case 'center':
        return WrapAlignment.center;
      case 'end':
        return WrapAlignment.end;
      case 'spaceAround':
        return WrapAlignment.spaceAround;
      case 'spaceBetween':
        return WrapAlignment.spaceBetween;
      case 'spaceEvenly':
        return WrapAlignment.spaceEvenly;
      default:
        return WrapAlignment.start;
    }
  }

  WrapCrossAlignment _crossAlignment(String? value) {
    switch (value) {
      case 'center':
        return WrapCrossAlignment.center;
      case 'end':
        return WrapCrossAlignment.end;
      default:
        return WrapCrossAlignment.start;
    }
  }
}
