import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveSingleChildScrollView
    extends LiveStateWidget<LiveSingleChildScrollView> {
  const LiveSingleChildScrollView({super.key, required super.state});

  @override
  State<LiveSingleChildScrollView> createState() =>
      _LiveSingleChildScrollViewState();
}

class _LiveSingleChildScrollViewState
    extends StateWidget<LiveSingleChildScrollView> {
  final attributes = [
    'scrollDirection',
    'reverse',
    'padding',
    'primary',
    'dragStartBehavior',
    'keyboardDismissBehavior',
    'restorationId',
    'clipBehavior'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: axisAttribute('scrollDirection') ?? Axis.vertical,
      reverse: booleanAttribute('reverse') ?? false,
      padding: marginOrPaddingAttribute('padding'),
      primary: booleanAttribute('primary'),
      dragStartBehavior: dragStartBehaviorAttribute('dragStartBehavior') ??
          DragStartBehavior.start,
      keyboardDismissBehavior: scrollViewKeyboardDismissBehaviorAttribute(
              'keyboardDismissBehavior') ??
          ScrollViewKeyboardDismissBehavior.manual,
      restorationId: getAttribute('restorationId'),
      clipBehavior: clipAttribute('clipBehavior') ?? Clip.hardEdge,
      child: singleChild(),
    );
  }
}
