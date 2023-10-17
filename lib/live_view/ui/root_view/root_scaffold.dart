import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/routes/live_router_delegate.dart';
import 'package:liveview_flutter/live_view/ui/components/live_bottom_navigation_bar.dart';
import 'package:liveview_flutter/live_view/ui/components/state_widget.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_bottom_navigation_bar.dart';

class RootScaffold extends StatefulWidget {
  final LiveView view;
  const RootScaffold({super.key, required this.view});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  List<Widget> children = [];

  @override
  void initState() {
    widget.view.router.addListener(routeChange);
    super.initState();
  }

  void routeChange() {}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: RootAppBar(view: widget.view),
        body: Router(
          routerDelegate: widget.view.router,
          backButtonDispatcher: RootBackButtonDispatcher(),
        ),
        bottomNavigationBar: RootBottomNavigationBar(view: widget.view));
  }
}
