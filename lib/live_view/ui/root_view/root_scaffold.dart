import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/state/state_child.dart';
import 'package:liveview_flutter/live_view/ui/components/live_navigation_rail.dart';
import 'package:liveview_flutter/live_view/ui/loading/reload_widget.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_app_bar.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_bottom_navigation_bar.dart';
import 'package:throttled/throttled.dart';

class RootScaffold extends StatefulWidget {
  final LiveView view;
  const RootScaffold({super.key, required this.view});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  List<Widget> children = [];
  bool isLiveReloading = false;
  LiveNavigationRail? railBar;

  @override
  void initState() {
    widget.view.eventHub.on('live-reload:start', (_) => setState(() {}));
    widget.view.eventHub.on('live-reload:end', (_) => setState(() {}));
    widget.view.router.addListener(routeChange);
    super.initState();
  }

  void routeChange() {
    setState(() {
      railBar = StateChild.extractWidgetChild<LiveNavigationRail>(
          List<Widget>.from(widget.view.router.pages.last.widgets));
    });
  }

  Widget mapRailBar(Widget child) {
    if (railBar == null) {
      return child;
    }
    return Row(children: [railBar!, Expanded(child: child)]);
  }

  @override
  Widget build(BuildContext context) {
    var child = SafeArea(
        child: Router(
      routerDelegate: widget.view.router,
      backButtonDispatcher: RootBackButtonDispatcher(),
    ));
    var view = Scaffold(
        appBar: RootAppBar(view: widget.view),
        body: NotificationListener<SizeChangedLayoutNotification>(
            onNotification: (_) {
              if (widget.view.throttleSpammyCalls) {
                throttle('window_resize',
                    () => widget.view.eventHub.fire('phx:window:resize'),
                    cooldown: const Duration(milliseconds: 30));
              } else {
                widget.view.eventHub.fire('phx:window:resize');
              }
              return true;
            },
            child: mapRailBar(SizeChangedLayoutNotifier(
                child: widget.view.isLiveReloading
                    ? Stack(children: [child, const ReloadWidget()])
                    : child))),
        bottomNavigationBar: RootBottomNavigationBar(view: widget.view));
    return view;
  }
}
