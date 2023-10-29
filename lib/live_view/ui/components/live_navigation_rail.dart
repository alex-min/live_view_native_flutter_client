import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/boolean.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/mapping/margin.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_text.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class LiveNavigationRail extends LiveStateWidget<LiveNavigationRail> {
  const LiveNavigationRail({super.key, required super.state});

  @override
  State<LiveNavigationRail> createState() => _LiveNavigationRailState();
}

class _LiveNavigationRailState extends StateWidget<LiveNavigationRail> {
  @override
  HandleClickState handleClickState() => HandleClickState.manual;
  int selected = 0;
  bool allowInitialValueChange = true;
  var attributes = [
    'labelType',
    'useIndicator',
    'indicatorColor',
    'disabled',
    'initialValue'
  ];

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    if (allowInitialValueChange) {
      allowInitialValueChange = false;
      selected = intAttribute('initialValue') ?? 0;
    }
  }

  List<(Map<String, String?>, NavigationRailDestination)> barItems() {
    return childrenNodesOf(node, 'NavigationRailDestination')
        .map((destination) {
      var attributes = bindChildVariableAttributes(
          destination,
          ['icon', 'label', 'indicatorColor', 'disabled', 'padding'],
          widget.state.variables);
      var children =
          StateChild.multipleChildren(widget.state.copyWith(node: destination));
      Widget? icon;
      Widget? label;
      if (attributes['icon'] != null) {
        icon = Icon(getIcon(attributes['icon']!));
      }
      icon ??= StateChild.extractChild<LiveIcon>(children);
      if (attributes['label'] != null) {
        label = Text(attributes['label']!);
      }
      label ??= StateChild.extractChild<LiveText>(children);

      return (
        attributes,
        NavigationRailDestination(
            padding: getMarginOrPadding(attributes['padding']),
            icon: icon ?? defaultIcon,
            label: label ?? const Text(''),
            indicatorColor: getColor(
              context,
              attributes['indicatorColor'],
            ),
            disabled: getBoolean(attributes['disabled']) ?? false)
      );
    }).toList();
  }

  @override
  Widget render(BuildContext context) {
    var items = barItems();
    return NavigationRail(
        indicatorColor: colorAttribute(context, 'indicatorColor'),
        onDestinationSelected: (newSelection) {
          setState(() => selected = newSelection);
          // tapping on the item
          executeTapEventsManually(fromAttributes: items[selected].$1);

          // tapping itself
          executeTapEventsManually();
        },
        useIndicator: booleanAttribute('useIndicator'),
        labelType: getNavigationRailLabelTypeAttribute('labelType'),
        destinations: items.map((e) => e.$2).toList(),
        selectedIndex: selected);
  }
}
