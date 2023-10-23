import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_label_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveNavigationRailDestination
    extends LiveStateWidget<LiveNavigationRailDestination> {
  const LiveNavigationRailDestination({super.key, required super.state});

  @override
  State<LiveNavigationRailDestination> createState() =>
      _LiveNavigationRailDestinationState();
}

class _LiveNavigationRailDestinationState
    extends StateWidget<LiveNavigationRailDestination> {
  Widget? displayedIcon;

  @override
  void onStateChange(Map<String, dynamic> diff) => reloadBar();

  @override
  void onWipeState() => reloadBar();

  void reloadBar() {
    reloadAttributes(node, ['indicatorColor', 'padding', 'label', 'icon']);
    reloadPredefinedAttributes(node);

    var children = multipleChildren();
    Widget? icon = StateChild.extractChild<LiveIconAttribute>(children);
    var iconAttribute = getAttribute('icon');
    var selectedIcon = StateChild.extractChild<LiveIconAttribute>(children);
    Widget? label = StateChild.extractChild<LiveLabelAttribute>(children);
    var labelAttribute = getAttribute('label');
    if (label == null && labelAttribute != null) {
      label = Text(labelAttribute);
    }
    if (icon == null && iconAttribute != null) {
      icon = Icon(getIcon(iconAttribute));
    }
    displayedIcon = icon;

    Map<String, String?> data = {};
    for (var key in defaultListenedKeys) {
      var attribute = getAttribute(key);
      if (attribute != null) {
        data[key] = attribute;
      }
    }

    LiveNavigationRailNotification(
      icon: icon ?? const SizedBox.shrink(),
      selectedIcon: selectedIcon,
      label: label ?? const SizedBox.shrink(),
      indicatorColor: getAttribute('indicatorColor'),
      padding: getAttribute('padding'),
      extraData: data,
    ).dispatch(context);
  }

  @override
  Widget render(BuildContext context) {
    return displayedIcon != null
        ? Container(
            key: ValueKey<int>(widget.state.node.hashCode),
            child: displayedIcon)
        : const SizedBox.shrink();
  }
}
