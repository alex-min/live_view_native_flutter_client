import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/live_appbar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveScaffold extends LiveStateWidget {
  const LiveScaffold({super.key, required super.state});

  @override
  State<LiveScaffold> createState() => _LiveScaffoldState();
}

class _LiveScaffoldState extends StateWidget<LiveScaffold> {
  @override
  void onStateChange(Map<String, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    var children = multipleChildren();
    var appBar = extractChild<LiveAppBar>(children);

    return Scaffold(appBar: appBar, body: body(children));
  }
}
