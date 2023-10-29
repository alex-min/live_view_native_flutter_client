import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/bottom_navigation_bar_type.dart';
import 'package:liveview_flutter/live_view/mapping/colors.dart';
import 'package:liveview_flutter/live_view/mapping/icons.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/utils.dart';

class LiveBottomNavigationBar extends LiveStateWidget<LiveBottomNavigationBar> {
  const LiveBottomNavigationBar({super.key, required super.state});

  @override
  State<LiveBottomNavigationBar> createState() =>
      _LiveBottomNavigationBarState();
}

class _LiveBottomNavigationBarState
    extends StateWidget<LiveBottomNavigationBar> {
  @override
  HandleClickState handleClickState() => HandleClickState.manual;
  List<String> attributes = [
    'showSelectedLabels',
    'showUnselectedLabels',
    'initialValue',
    'selectedItemColor',
    'unselectedItemColor',
    'backgroundColor',
    'elevation',
    'type',
    'selectedFontSize',
    'unselectedFontSize',
    'fixedColor',
    'iconSize',
    'enableFeedback',
    'landscapeLayout'
  ];
  List<String> childAttributes = [
    'label',
    'name',
    'icon',
    'backgroundColor',
    'tooltip',
  ];
  int _currentIndex = 0;
  bool allowInitialValueChange = true;

  @override
  void onWipeState() {
    allowInitialValueChange = true;
    super.onWipeState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(node, attributes);
    if (allowInitialValueChange) {
      _currentIndex = intAttribute('initialValue') ?? 0;
      allowInitialValueChange = false;
    }
  }

  List<(Map<String, String?>, BottomNavigationBarItem)> bottomBarItems() {
    return childrenNodesOf(node, 'BottomNavigationBarItem').map((button) {
      var attributes = bindChildVariableAttributes(
          button, childAttributes, widget.state.variables);
      var children =
          StateChild.multipleChildren(widget.state.copyWith(node: button));

      Widget? icon;
      if (attributes['icon'] != null) {
        icon = Icon(getIcon(attributes['icon']!));
      }
      icon ??= StateChild.extractChild<LiveIcon>(children);

      return (
        attributes,
        BottomNavigationBarItem(
            icon: icon ?? defaultIcon,
            label: attributes['label'] ?? '',
            backgroundColor: getColor(context, attributes['backgroundColor']),
            tooltip: attributes['tooltip'])
      );
    }).toList();
  }

  @override
  Widget render(BuildContext context) {
    var children = bottomBarItems();

    if (children.length < 2) {
      if (kDebugMode) {
        throw Exception(
            'Please add more than one "BottomNavigationBarItem" to <BottomNavigationBar>, flutter needs more than two at a minimum');
      } else {
        return const SizedBox.shrink();
      }
    }

    var type = getBottomNavigationBarType(getAttribute('type'));
    if (type == null && children.length > 3) {
      // Flutter automatically transforms the bottom navigation bar into shifting
      // if you have more than 3 items which makes everything disapear with the theme
      type = BottomNavigationBarType.fixed;
    }

    return BottomNavigationBar(
        type: type,
        elevation: doubleAttribute('elevation'),
        currentIndex: _currentIndex,
        onTap: (selected) {
          setState(() {
            _currentIndex = selected;
          });

          // tapping on the item
          executeTapEventsManually(fromAttributes: children[selected].$1);

          // tapping itself
          executeTapEventsManually();
        },
        enableFeedback: booleanAttribute('enableFeedback'),
        iconSize: doubleAttribute('iconSize') ?? 24.0,
        fixedColor: colorAttribute(context, 'fixedColor'),
        unselectedItemColor: colorAttribute(context, 'unselectedItemColor'),
        selectedItemColor: colorAttribute(context, 'selectedItemColor'),
        backgroundColor: colorAttribute(context, 'backgroundColor'),
        showSelectedLabels: booleanAttribute('showSelectedLabels') ?? true,
        showUnselectedLabels: booleanAttribute('showUnselectedLabels') ?? true,
        selectedFontSize: doubleAttribute('selectedFontSize') ?? 14.0,
        unselectedFontSize: doubleAttribute('unselectedFontSize') ?? 12.0,
        landscapeLayout: getBottomNavigationBarLandscapeLayout(
            getAttribute('landscapeLayout')),
        items: children.map((c) => c.$2).toList());
  }
}
