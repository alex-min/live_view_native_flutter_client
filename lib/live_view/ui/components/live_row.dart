import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/axis_alignment.dart';
import 'package:liveview_flutter/live_view/mapping/text_baseline.dart';
import 'package:liveview_flutter/live_view/mapping/text_direction.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveRow extends LiveStateWidget<LiveRow> {
  const LiveRow({super.key, required super.state});

  @override
  State<LiveRow> createState() => _LiveColState();
}

class _LiveColState extends StateWidget<LiveRow> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
        'mainAxisAlignment',
        'crossAxisAlignment',
        'textDirection',
        'mainAxisSize',
        'verticalDirection',
        'textBaseline'
      ]);

  @override
  Widget render(BuildContext context) {
    return Row(
        mainAxisAlignment:
            getMainAxisAlignment(getAttribute('mainAxisAlignment')) ??
                MainAxisAlignment.start,
        crossAxisAlignment:
            getCrossAxisAlignment(getAttribute('crossAxisAlignment')) ??
                CrossAxisAlignment.center,
        mainAxisSize:
            getMainAxisSize(getAttribute('mainAxisSize')) ?? MainAxisSize.max,
        textDirection: getTextDirection(getAttribute('textDirection')),
        verticalDirection:
            getVerticalDirection(getAttribute('verticalDirection')) ??
                VerticalDirection.down,
        textBaseline: getTextBaseline(getAttribute('textBaseline')),
        children: multipleChildren());
  }
}
