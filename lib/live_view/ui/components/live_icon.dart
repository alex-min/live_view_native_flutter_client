import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/number.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/mapping/text_direction.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveIcon extends LiveStateWidget<LiveIcon> {
  const LiveIcon({super.key, required super.state});

  @override
  State<LiveIcon> createState() => _LiveIconState();
}

class _LiveIconState extends StateWidget<LiveIcon> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes([
      'name',
      'size',
      'fill',
      'weight',
      'grade',
      'opticalSize',
      'color',
      'semanticLabel',
      'textDirection'
    ]);
  }

  @override
  Widget render(BuildContext context) {
    return Icon(getIcon(getAttribute('name')),
        size: getDouble(getAttribute('size')),
        fill: getDouble(getAttribute('fill')),
        weight: getDouble(getAttribute('weight')),
        grade: getDouble(getAttribute('grade')),
        opticalSize: getDouble(getAttribute('opticalSize')),
        color: getColor(context, getAttribute('color')),
        semanticLabel: getAttribute('semanticLabel'),
        textDirection: getTextDirection(getAttribute('textDirection')));
  }
}
