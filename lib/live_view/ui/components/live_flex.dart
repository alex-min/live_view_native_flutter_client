import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/axis_alignment.dart';
import 'package:liveview_flutter/live_view/mapping/text_baseline.dart';
import 'package:liveview_flutter/live_view/mapping/text_direction.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveFlex extends LiveStateWidget<LiveFlex> {
  const LiveFlex({super.key, required super.state});

  @override
  State<LiveFlex> createState() => _LiveColState();
}

class _LiveColState extends StateWidget<LiveFlex> {
  @override
  void initState() {
    super.initState();
    // Rebuild when a server diff targets a comprehension or conditional in
    // this flex's subtree, so flattened dynamic children stay up to date.
    listenInnerTextKeys();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
    'mainAxisAlignment',
    'crossAxisAlignment',
    'textDirection',
    'mainAxisSize',
    'verticalDirection',
    'textBaseline',
    'direction',
  ]);

  @override
  Widget render(BuildContext context) {
    return Flex(
      direction:
          getAttribute('direction') == 'row' ? Axis.horizontal : Axis.vertical,
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
      children: flexChildren(),
    );
  }
}
