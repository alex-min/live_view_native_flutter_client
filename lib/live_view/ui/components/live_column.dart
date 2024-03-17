import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/axis_alignment.dart';
import 'package:liveview_flutter/live_view/mapping/text_baseline.dart';
import 'package:liveview_flutter/live_view/mapping/text_direction.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveColumn extends LiveStateWidget<LiveColumn> {
  const LiveColumn({super.key, required super.state});

  @override
  State<LiveColumn> createState() => _LiveColState();
}

class _LiveColState extends StateWidget<LiveColumn> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
        'mainAxisAlignment',
        'crossAxisAlignment',
        'textDirection',
        'verticalDirection',
        'textBaseline'
      ]);

  @override
  Widget render(BuildContext context) {
    return Column(
      mainAxisAlignment:
          getMainAxisAlignment(getAttribute('mainAxisAlignment')) ??
              MainAxisAlignment.start,
      crossAxisAlignment:
          getCrossAxisAlignment(getAttribute('crossAxisAlignment')) ??
              CrossAxisAlignment.center,
      textDirection: getTextDirection(getAttribute('textDirection')),
      verticalDirection:
          getVerticalDirection(getAttribute('verticalDirection')) ??
              VerticalDirection.down,
      textBaseline: getTextBaseline(getAttribute('textBaseline')),
      children: multipleChildren(),
    );
  }
}
