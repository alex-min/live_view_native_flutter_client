import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_leading_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/live_title_attribute.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveAppBar extends LiveStateWidget implements PreferredSizeWidget {
  const LiveAppBar({super.key, required super.state})
      : preferredSize = const Size.fromHeight(kToolbarHeight);

  @override
  final Size preferredSize;

  @override
  State<LiveAppBar> createState() => _LiveAppBarState();
}

class _LiveAppBarState extends StateWidget<LiveAppBar> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var title = extractChild<LiveTitleAttribute>(children);
    var leading = extractChild<LiveLeadingAttribute>(children);

    return AppBar(
      title: title,
      leading: leading,
      actions: children,
    );
  }
}
