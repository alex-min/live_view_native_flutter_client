import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveSafeArea extends LiveStateWidget<LiveSafeArea> {
  const LiveSafeArea({super.key, required super.state});

  @override
  State<LiveSafeArea> createState() => _LiveSafeAreaState();
}

class _LiveSafeAreaState extends StateWidget<LiveSafeArea> {
  final attributes = [
    'left',
    'top',
    'right',
    'bottom',
    'minimum',
    'maintainBottomViewPadding',
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) =>
      reloadAttributes(node, attributes);

  @override
  Widget render(BuildContext context) {
    return SafeArea(
      left: booleanAttribute('left') ?? true,
      top: booleanAttribute('top') ?? true,
      right: booleanAttribute('right') ?? true,
      bottom: booleanAttribute('bottom') ?? true,
      minimum: marginOrPaddingAttribute('minimum') ?? EdgeInsets.zero,
      maintainBottomViewPadding:
          booleanAttribute('maintainBottomViewPadding') ?? false,
      child: singleChild(),
    );
  }
}
