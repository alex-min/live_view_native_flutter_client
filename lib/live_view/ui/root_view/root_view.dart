import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_material_app.dart';
import 'package:provider/provider.dart';

class LiveRootView extends StatefulWidget {
  final LiveView view;
  const LiveRootView({super.key, required this.view});

  @override
  State<LiveRootView> createState() => _LiveRootViewState();
}

class _LiveRootViewState extends State<LiveRootView> {
  LiveView get liveView => widget.view;

  @override
  Widget build(BuildContext context) {
    if (liveView.catchExceptions) {
      ErrorWidget.builder = (err) {
        return liveView.fallbackWidgets.buildFlutterError(
          liveView,
          FlutterErrorDetails(
            exception: err,
            stack: StackTrace.current,
          ),
        );
      };
    }
    return MultiProvider(providers: [
      ChangeNotifierProvider.value(value: liveView.changeNotifier),
      ChangeNotifierProvider.value(value: liveView.connectionNotifier),
      ChangeNotifierProvider.value(value: liveView.themeSettings)
    ], child: LiveViewRootMaterialApp(view: widget.view));
  }
}
