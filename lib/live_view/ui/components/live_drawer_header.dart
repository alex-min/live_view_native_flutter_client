import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDrawerHeader extends LiveStateWidget<LiveDrawerHeader> {
  const LiveDrawerHeader({super.key, required super.state});

  @override
  State<LiveDrawerHeader> createState() => _LiveDrawerHeaderState();
}

class _LiveDrawerHeaderState extends StateWidget<LiveDrawerHeader> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes(node, [
        'decoration',
      ]);

  @override
  Widget render(BuildContext context) {
    return DrawerHeader(
      decoration: decorationAttribute(context, 'decoration'),
      margin:
          edgeInsetsAttribute('margin') ?? const EdgeInsets.only(bottom: 8.0),
      padding: edgeInsetsAttribute('padding') ??
          const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 8.0),
      duration:
          Duration(milliseconds: (doubleAttribute('duration') ?? 250).toInt()),
      child: singleChild(),
    );
  }
}
