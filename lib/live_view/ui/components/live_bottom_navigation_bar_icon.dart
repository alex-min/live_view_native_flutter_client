import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_icon.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveBottomNavigationBarIcon
    extends LiveStateWidget<LiveBottomNavigationBarIcon> {
  const LiveBottomNavigationBarIcon({super.key, required super.state});

  @override
  State<LiveBottomNavigationBarIcon> createState() =>
      _LiveBottomNavigationBarItemState();
}

class _LiveBottomNavigationBarItemState
    extends StateWidget<LiveBottomNavigationBarIcon> {
  @override
  void onStateChange(Map<String, dynamic> diff) {
    reloadAttributes(['label', 'backgroundColor']);
    reloadPredefinedAttributes();
    var data = {
      'label': getAttribute('label'),
      'backgroundColor': getAttribute('backgroundColor'),
    };
    for (var key in defaultListenedKeys) {
      var attribute = getAttribute(key);
      if (attribute != null) {
        data[key] = attribute;
      }
    }
    BottomNavigationBarNotification(data: data).dispatch(context);
  }

  @override
  Widget render(BuildContext context) {
    return LiveIcon(state: widget.state);
  }
}
