import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveDrawer extends LiveStateWidget<LiveDrawer> {
  const LiveDrawer({super.key, required super.state});

  @override
  State<LiveDrawer> createState() => _LiveDrawerState();
}

class _LiveDrawerState extends StateWidget<LiveDrawer> {
  @override
  void onStateChange(Map<String, dynamic> diff) => reloadAttributes([
        'backgroundColor',
        'elevation',
        'shadowColor',
        'surfaceTintColor',
        'width',
        'semanticLabel',
      ]);

  @override
  Widget render(BuildContext context) {
    return Drawer(
        backgroundColor: colorAttribute('backgroundColor'),
        elevation: doubleAttribute('elevation'),
        shadowColor: colorAttribute('shadowColor'),
        surfaceTintColor: colorAttribute('surfaceTintColor'),
        width: doubleAttribute('width'),
        semanticLabel: getAttribute('semanticLabel'),
        child: singleChild());
  }
}
