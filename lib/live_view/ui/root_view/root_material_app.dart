
import 'package:flutter/material.dart';
import 'package:liveview_flutter/live_view/live_view.dart';
import 'package:liveview_flutter/live_view/reactive/theme_settings.dart';
import 'package:liveview_flutter/live_view/ui/root_view/root_scaffold.dart';
import 'package:provider/provider.dart';

class LiveViewRootMaterialApp extends StatefulWidget {
  final LiveView view;
  const LiveViewRootMaterialApp({super.key, required this.view});

  @override
  State<LiveViewRootMaterialApp> createState() =>
      _LiveViewRootMaterialAppState();
}

class _LiveViewRootMaterialAppState extends State<LiveViewRootMaterialApp> {
  @override
  Widget build(BuildContext context) {
    var theme = Provider.of<ThemeSettings>(context);
    return MaterialApp(
        title: 'Flutter Demo',
        themeMode: theme.themeMode,
        theme: theme.lightTheme,
        darkTheme: theme.darkTheme,
        home: RootScaffold(view: widget.view));
  }
}
