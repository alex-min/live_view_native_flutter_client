import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail_destination.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveNavigationRailNotification extends Notification {
  final Widget icon;
  final Widget? selectedIcon;
  final Widget label;
  final String? indicatorColor;
  final String? padding;
  final Map<String, String?> extraData;

  const LiveNavigationRailNotification(
      {required this.icon,
      required this.selectedIcon,
      required this.label,
      required this.indicatorColor,
      required this.padding,
      required this.extraData});
}

class LiveNavigationRail extends LiveStateWidget<LiveNavigationRail> {
  const LiveNavigationRail({super.key, required super.state});

  @override
  State<LiveNavigationRail> createState() => _LiveNavigationRailState();
}

class _LiveNavigationRailState extends StateWidget<LiveNavigationRail> {
  Map<int, LiveNavigationRailNotification?> _itemsExtraData = {};

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {});
    });
    super.initState();
  }

  @override
  void onWipeState() {
    _itemsExtraData = {};
    setState(() {});
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, ['labelType', 'selectedIndex']);
  }

  bool onChildChanges(int index, LiveNavigationRailNotification data) {
    _itemsExtraData[index] = data;
    Future.delayed(Duration.zero, () => setState(() {}));
    return true;
  }

  @override
  Widget render(BuildContext context) {
    var children = StateChild.extractChildren<LiveNavigationRailDestination>(
            multipleChildren())
        .asMap()
        .entries
        .map((w) {
      return NotificationListener<LiveNavigationRailNotification>(
          onNotification: (notif) {
            onChildChanges(w.key, notif);
            return true;
          },
          child: w.value);
    }).toList();
    return NavigationRail(
        // the key is necessary because we don't want to cache the appbar accross renders
        key: ValueKey<int>(widget.state.node.hashCode),
        labelType: getNavigationRailLabelTypeAttribute('labelType'),
        useIndicator: true,
        destinations: children.asMap().entries.map((railDestination) {
          var data = _itemsExtraData[railDestination.key];
          return NavigationRailDestination(
              icon: railDestination.value,
              selectedIcon: data?.selectedIcon,
              indicatorColor: getColor(context, data?.indicatorColor),
              label: data?.label ?? const SizedBox.shrink(),
              padding: getMarginOrPadding(data?.padding));
        }).toList(),
        onDestinationSelected: (selected) {
          executeTapEventsManually(
              fromAttributes: _itemsExtraData[selected]?.extraData ?? {});
        },
        selectedIndex: intAttribute('selectedIndex'));
  }
}
