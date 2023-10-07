import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';

class LiveListView extends LiveStateWidget {
  const LiveListView({super.key, required super.state});

  @override
  State<LiveListView> createState() => _LiveListViewState();
}

class _LiveListViewState extends StateWidget<LiveListView> {
  @override
  void onStateChange(Map<dynamic, dynamic> diff) {}

  @override
  Widget render(BuildContext context) {
    return ListView(children: multipleChildren());
  }
}
