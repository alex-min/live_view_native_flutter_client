import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:liveview_flutter/liveview_flutter.dart';

import 'billing/revenuecat_plugin.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final view = await LiveView.withPersistentCache();
  await view.installPlugins([RevenueCatPlugin()]);
  runApp(MyApp(view: view));
}

class MyApp extends StatefulWidget {
  final LiveView view;

  const MyApp({super.key, required this.view});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  LiveView get view => widget.view;

  @override
  initState() {
    Future.microtask(boot);
    super.initState();
  }

  void boot() async {
    if (kIsWeb) {
      await view.connect('http://localhost:4000/');
      return;
    }

    await view.connect(
      Platform.isAndroid
          ?
          // android emulator
          'http://10.0.2.2:4000'
          // computer
          : 'http://localhost:4000',
    );
  }

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return view.rootView;
  }
}
