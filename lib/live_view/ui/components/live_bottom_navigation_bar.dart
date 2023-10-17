import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/mapping/bottom_navigation_bar_type.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class BottomNavigationBarNotification extends Notification {
  final Map<String, dynamic> data;

  const BottomNavigationBarNotification({required this.data});
}

class LiveBottomNavigationBar extends LiveStateWidget<LiveBottomNavigationBar> {
  const LiveBottomNavigationBar({super.key, required super.state});

  @override
  State<LiveBottomNavigationBar> createState() =>
      _LiveBottomNavigationBarState();
}

class _LiveBottomNavigationBarState
    extends StateWidget<LiveBottomNavigationBar> {
  final Map<int, Map<String, dynamic>> _itemsExtraData = {};

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      setState(() {});
    });
    super.initState();
  }

  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes([
      'selectedItemColor',
      'fixedColor',
      'unselectedItemColor',
      'backgroundColor',
      'currentIndex',
      'type',
      'selectedFontSize',
      'unselectedFontSize',
      'showSelectedLabels',
      'showUnselectedLabels'
    ]);
  }

  bool onChildChanges(int index, BottomNavigationBarNotification data) {
    if (mapEquals(data.data, _itemsExtraData[index])) {
      return true;
    }

    _itemsExtraData[index] = data.data;
    if (mounted) {
      try {
        setState(() {});
      } catch (e) {
        // we don't mind if it fails because the state is being rebuilt in the mean time
      }
    }
    return true;
  }

  @override
  Widget render(BuildContext context) {
    var children =
        extractChildren<LiveBottomNavigationBarIcon>(multipleChildren())
            .asMap()
            .entries
            .map((w) {
      return NotificationListener<BottomNavigationBarNotification>(
          onNotification: (notif) {
            onChildChanges(w.key, notif);
            return true;
          },
          child: w.value);
    }).toList();
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
        selectedItemColor: colorAttribute('selectedItemColor'),
        fixedColor: colorAttribute('fixedColor'),
        unselectedItemColor: colorAttribute('unselectedItemColor'),
        backgroundColor: colorAttribute('backgroundColor'),
        currentIndex: intAttribute('currentIndex') ?? 0,
        type: type,
        selectedFontSize: doubleAttribute('selectedFontSize') ?? 14.0,
        unselectedFontSize: doubleAttribute('unselectedFontSize') ?? 12.0,
        showSelectedLabels: booleanAttribute('showSelectedLabels'),
        showUnselectedLabels: booleanAttribute('showUnselectedLabels'),
        onTap: (tapped) {
          executeTapEventsManually(
              fromAttributes: _itemsExtraData[tapped] ?? {});
        },
        items: children.asMap().entries.map((item) {
          return BottomNavigationBarItem(
            icon: item.value,
            label: _itemsExtraData[item.key]?['label'] ?? '',
          );
        }).toList());
  }
}
